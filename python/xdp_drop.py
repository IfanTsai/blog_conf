#!/usr/bin/python3
from bcc import BPF
import json
import ctypes

b = BPF(text = '''
#include <uapi/linux/bpf.h>
#include <linux/in.h>
#include <linux/if_ether.h>
#include <linux/if_packet.h>
#include <linux/if_vlan.h>
#include <linux/ip.h>
#include <linux/ipv6.h>

BPF_HASH(ip_black_list, __be32);

struct vlanhdr {
    __be16 h_vlan_TCI;
    __be16 h_vlan_encapsulated_proto;
};

int xdp_dorp_black_ip(struct xdp_md *ctx) {
    void *data_end = (void *)(long)ctx->data_end;
    void *data = (void *)(long)ctx->data;

    /* eth */
    struct ethhdr *eth = data;
    __u64 nh_off = sizeof(*eth);
    if (unlikely(data + nh_off > data_end))
        return XDP_DROP;

    __be16 h_proto = eth->h_proto;

    /* vlan */
    __u64 vlanhdr_len = 0;
    // handle double tags in ethernet frames
    #pragma unroll
    for (int i = 0; i < 2; i++) {
        if (bpf_htons(ETH_P_8021Q) == h_proto || bpf_htons(ETH_P_8021AD) == h_proto) {
            struct vlanhdr *vhdr = data + nh_off;

            nh_off += sizeof(*vhdr);
            if (data + nh_off > data_end)
                return XDP_DROP;

            vlanhdr_len += sizeof(*vhdr);
            h_proto = vhdr->h_vlan_encapsulated_proto;
        }
    }

    /* ipv4 */
    if (bpf_htons(ETH_P_IP) != h_proto)
        return XDP_PASS;

    struct iphdr *ip = data + nh_off;
    if (unlikely((void *)ip + sizeof(*ip) > data_end))
        return XDP_DROP;

    /* check whether source ip is in the blacklist */
    __be32 source_ip = bpf_htonl(ip->saddr);
    if (ip_black_list.lookup(&source_ip))
        return XDP_DROP;

    return XDP_PASS;
}
''')

def load_xdp(nic, ip_black_list_path, is_xdp_generic=True):
    flags = 0
    if is_xdp_generic:
        flags |= BPF.XDP_FLAGS_SKB_MODE
    else:
        flags |= BPF.XDP_FLAGS_HW_MODE

    b.remove_xdp(nic, flags)

    # load xdp program and attach xdp
    fn = b.load_func('xdp_dorp_black_ip', BPF.XDP, None)
    b.attach_xdp(nic, fn, flags)

    ipstr2addr = lambda x:sum([256 ** j * int(i) for j, i in enumerate(x.split('.')[::-1])])

    # read ip black list json from file
    ip_black_list_dict = {}
    with open(ip_black_list_path, 'r') as f:
        ip_black_list_json = f.read()
        ip_black_list_dict = json.loads(ip_black_list_json)

    # write black ip to xdp map
    ip_black_list_map = b.get_table('ip_black_list')
    for k, _ in ip_black_list_dict.items():
        addr = ipstr2addr(k)
        ip_black_list_map[ctypes.c_uint(addr)] = ctypes.c_uint(1)
