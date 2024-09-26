#include <Timer.h>
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/protocol.h"
#include "../../includes/CommandMsg.h"
#include "../../includes/command.h"

#define NODETIMETOLIVE  22



module NeighborDiscoveryP {
    provides interface NeighborDiscovery;
    uses interface Random as Random;
    uses interface Timer<TMilli> as Timer;
    uses interface Hashmap<uint32_t> as NeighborCache;
    uses interface SimpleSend as Broadcast;
}

implementation {
    pack MessageToSend;

    //Helper function for creating packets
    void preparePacket(pack *pkt, uint16_t src, uint16_t dest, uint16_t ttl, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t len);

    command error_t NeighborDiscovery.initialize() {
        call Timer.startPeriodic(500 + (uint16_t)(call Random.rand16() % 500));
        dbg(NEIGHBOR_CHANNEL, "Node %d: Starting Neighbor Discovery\n", TOS_NODE_ID);
        return SUCCESS;
    }

    command void NeighborDiscovery.processDiscovery(pack* message) {
        dbg(NEIGHBOR_CHANNEL, "Processing Neighbor Discovery\n");

        if(message->TTL > 0 && message->protocol == PROTOCOL_PING) {
            dbg(NEIGHBOR_CHANNEL, "PING received, updating message\n");
            message->TTL--;
            message->src = TOS_NODE_ID;
            message->protocol = PROTOCOL_PINGREPLY;
            call Broadcast.send(*message, AM_BROADCAST_ADDR);
            //handling ping reply
        } else if (message->protocol == PROTOCOL_PINGREPLY && message->dest == 0) {
            dbg(NEIGHBOR_CHANNEL, "PING REPLY received, confirmed neighbor %d\n", message->src);
            //Insert or update neighbor in the neighborTable
            if (!call NeighborCache.contains(message->src)) {
                call NeighborCache.insert(message->src, NODETIMETOLIVE);
            }
        }
    }
    
    event void Timer.fired() {
        uint32_t* neighbors = call NeighborCache.getKeys();
        uint8_t dummyPayload = 0;
        uint16_t i = 0;
        dbg(NEIGHBOR_CHANNEL, "Timer fired event\n");

        for (i = 0; i < call NeighborCache.size(); i++) {
            if (neighbors[i] == 0) continue;
            if (call NeighborCache.get(neighbors[i]) == 0) {
                dbg(NEIGHBOR_CHANNEL, "Neighbor %d expired, removing\n", neighbors[i]);
                call NeighborCache.remove(neighbors[i]);
            } else {
                call NeighborCache.insert(neighbors[i], call NeighborCache.get(neighbors[i]) - 1);
            }
        }
        dbg(NEIGHBOR_CHANNEL, "Sending periodic broadcast\n");
        preparePacket(&MessageToSend, TOS_NODE_ID, 0, 1, PROTOCOL_PING, 0, &dummyPayload, PACKET_MAX_PAYLOAD_SIZE);
        call Broadcast.send(MessageToSend, AM_BROADCAST_ADDR);
    }

    command uint32_t* NeighborDiscovery.fetchNeighbors() {
        return call NeighborCache.getKeys();
    }

    command uint16_t NeighborDiscovery.fetchNeighborCount() {
        return call NeighborCache.size();
    }

    void preparePacket(pack *pkt, uint16_t src, uint16_t dest, uint16_t ttl, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t len) {
        dbg(NEIGHBOR_CHANNEL, "Preparing packet\n");
        pkt->src = src; pkt->dest = dest;
        pkt->TTL = ttl; pkt->seq = seq;
        pkt->protocol = protocol;
        memcpy(pkt->payload, payload, len);
    } 

    command void NeighborDiscovery.displayNeighbors() {
        uint16_t i = 0;
        uint32_t* neighbors = call NeighborCache.getKeys();
        dbg(NEIGHBOR_CHANNEL, "Displaying neighbor list\n");
        for(i = 0; i < call NeighborCache.size(); i++) {
            if(neighbors[i] != 0) {
                dbg(NEIGHBOR_CHANNEL, "\tNeighbor: %d\n", neighbors[i]);
            }
        }
    }

}
