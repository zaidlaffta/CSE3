#include <Timer.h>
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/protocol.h"
#include "../../includes/CommandMsg.h"
#include "../../includes/command.h"

#define NODETIMETOLIVE  22



/*
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
*/

module NeighborDiscoveryP {
    provides interface NeighborDiscovery;
    uses interface Random as Random;
    uses interface Timer<TMilli> as Timer;
    uses interface Hashmap<uint32_t> as NeighborTable;
    uses interface SimpleSend as Sender;
}

implementation {
    pack MsgToSend;

    // Packet constructor as given in the lab
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length);

    command error_t NeighborDiscovery.start() {
        call Timer.startPeriodic(500 + (uint16_t)(call Random.rand16() % 500));
        dbg(NEIGHBOR_CHANNEL, "Node %d: Began Neighbor Discovery\n", TOS_NODE_ID);
        return SUCCESS;
    }

    command void NeighborDiscovery.discover(pack* packet) {
        dbg(NEIGHBOR_CHANNEL, "In NeighborDiscovery.discover\n");

        // Handling PING messages
        if (packet->TTL > 0 && packet->protocol == PROTOCOL_PING) {
            dbg(NEIGHBOR_CHANNEL, "PING Neighbor Discovery\n");
            packet->TTL = packet->TTL - 1;
            packet->src = TOS_NODE_ID;
            packet->protocol = PROTOCOL_PINGREPLY;
            call Sender.send(*packet, AM_BROADCAST_ADDR);
        }
        // Handling PING REPLY messages
        else if (packet->protocol == PROTOCOL_PINGREPLY && packet->dest == 0) {
            dbg(NEIGHBOR_CHANNEL, "PING REPLY Neighbor Discovery, Confirmed neighbor %d\n", packet->src);

            // Insert or update neighbor in the NeighborTable
            if (!call NeighborTable.contains(packet->src)) {
                call NeighborTable.insert(packet->src, NODETIMETOLIVE); // New neighbor
                dbg(NEIGHBOR_CHANNEL, "New neighbor discovered: %d\n", packet->src);
            } else {
                call NeighborTable.insert(packet->src, NODETIMETOLIVE); // Update TTL for existing neighbor
                dbg(NEIGHBOR_CHANNEL, "Updated TTL for neighbor: %d\n", packet->src);
            }
        }
    }

    event void Timer.fired() {
        uint32_t* neighbors = call NeighborTable.getKeys();
        uint16_t i;
        dbg(NEIGHBOR_CHANNEL, "In Timer fired\n");

        for (i = 0; i < call NeighborTable.size(); i++) {
            if (neighbors[i] == 0) {
                continue; // Skip invalid neighbors
            }

            uint16_t ttl = call NeighborTable.get(neighbors[i]);
            if (ttl == 0) {
                dbg(NEIGHBOR_CHANNEL, "Neighbor %d has expired. Removing...\n", neighbors[i]);
                call NeighborTable.remove(neighbors[i]);
            } else {
                dbg(NEIGHBOR_CHANNEL, "Decreasing TTL for neighbor %d. TTL: %d\n", neighbors[i], ttl);
                call NeighborTable.insert(neighbors[i], ttl - 1);
            }
        }

        // Broadcast discovery packet
        uint8_t payload = 0;
        makePack(&MsgToSend, TOS_NODE_ID, 0, 1, PROTOCOL_PING, 0, &payload, PACKET_MAX_PAYLOAD_SIZE);
        call Sender.send(MsgToSend, AM_BROADCAST_ADDR);
    }

    command uint32_t* NeighborDiscovery.getNeighbors() {
        return call NeighborTable.getKeys();
    }

    command uint16_t NeighborDiscovery.getNeighborListSize() {
        return call NeighborTable.size();
    }

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length) {
        dbg(NEIGHBOR_CHANNEL, "Making packet\n");
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, payload, length);
    }

    command void NeighborDiscovery.printNeighbors() {
        uint16_t i;
        uint32_t* neighbors = call NeighborTable.getKeys();
        dbg(NEIGHBOR_CHANNEL, "Printing Neighbors:\n");

        for (i = 0; i < call NeighborTable.size(); i++) {
            if (neighbors[i] != 0) {
                dbg(NEIGHBOR_CHANNEL, "\tNeighbor: %d\n", neighbors[i]);
            }
        }
    }
}

