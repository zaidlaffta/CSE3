#include <Timer.h>
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/protocol.h"
#include "../../includes/CommandMsg.h"
#include "../../includes/command.h"

#define NODETIMETOLIVE  22


module NeighborDiscoveryP {
    provides interface NeighborDiscovery;
    uses interface Random as RandGen;
    uses interface Timer<TMilli> as NeighborTimer;
    uses interface Hashmap<uint32_t> as NeighborMap;
    uses interface SimpleSend as PacketSender;
}

implementation {
    pack packetToSend;

    void preparePacket(pack *pkt, uint16_t source, uint16_t destination, uint16_t ttl, uint16_t protocolType, uint16_t sequence, uint8_t* data, uint8_t dataLength);

    command error_t NeighborDiscovery.start() {
        call NeighborTimer.startPeriodic(500 + (uint16_t)(call RandGen.rand16() % 500));
        dbg(NEIGHBOR_CHANNEL, "Node %d: Neighbor discovery initiated\n", TOS_NODE_ID);
        return SUCCESS;
    }

    command void NeighborDiscovery.discover(pack* receivedPacket) {
        dbg(NEIGHBOR_CHANNEL, "NeighborDiscovery: Processing incoming packet\n");

        if (receivedPacket->TTL > 0 && receivedPacket->protocol == PROTOCOL_PING) {
            dbg(NEIGHBOR_CHANNEL, "Processing PING packet\n");
            receivedPacket->TTL--;
            receivedPacket->src = TOS_NODE_ID;
            receivedPacket->protocol = PROTOCOL_PINGREPLY;
            call PacketSender.send(*receivedPacket, AM_BROADCAST_ADDR);
        } 
        else if (receivedPacket->protocol == PROTOCOL_PINGREPLY && receivedPacket->dest == 0) {
            dbg(NEIGHBOR_CHANNEL, "Received PING REPLY, Neighbor confirmed: %d\n", receivedPacket->src);
            if (!call NeighborMap.contains(receivedPacket->src)) {
                call NeighborMap.insert(receivedPacket->src, NODETIMETOLIVE);
            }
        }
    }

    event void NeighborTimer.fired() {
        uint32_t* neighborList = call NeighborMap.getKeys();
        uint8_t payloadData = 0;
        uint16_t idx = 0;

        dbg(NEIGHBOR_CHANNEL, "NeighborTimer fired: Checking neighbors\n");

        for (idx = 0; idx < call NeighborMap.size(); idx++) {
            if (neighborList[idx] == 0) {
                continue;
            }
            if (call NeighborMap.get(neighborList[idx]) == 0) {
                dbg(NEIGHBOR_CHANNEL, "Neighbor %d has expired, removing\n", neighborList[idx]);
                call NeighborMap.remove(neighborList[idx]);
            } 
            else {
                call NeighborMap.insert(neighborList[idx], call NeighborMap.get(neighborList[idx]) - 1);
            }
        }

        dbg(NEIGHBOR_CHANNEL, "Preparing new PING packet\n");
        preparePacket(&packetToSend, TOS_NODE_ID, 0, 1, PROTOCOL_PING, 0, &payloadData, PACKET_MAX_PAYLOAD_SIZE);
        call PacketSender.send(packetToSend, AM_BROADCAST_ADDR);
    }

    command uint32_t* NeighborDiscovery.getNeighbors() {
        return call NeighborMap.getKeys();
    }

    command uint16_t NeighborDiscovery.getNeighborListSize() {
        return call NeighborMap.size();
    }

    void preparePacket(pack *pkt, uint16_t source, uint16_t destination, uint16_t ttl, uint16_t protocolType, uint16_t sequence, uint8_t* data, uint8_t dataLength) {
        dbg(NEIGHBOR_CHANNEL, "Preparing packet with TTL: %d\n", ttl);
        pkt->src = source;
        pkt->dest = destination;
        pkt->TTL = ttl;
        pkt->seq = sequence;
        pkt->protocol = protocolType;
        memcpy(pkt->payload, data, dataLength);
    }

    command void NeighborDiscovery.printNeighborList() {
        uint16_t i = 0;
        uint32_t* neighbors = call NeighborMap.getKeys();
        dbg(NEIGHBOR_CHANNEL, "Listing neighbors:\n");
        for (i = 0; i < call NeighborMap.size(); i++) {
            if (neighbors[i] != 0) {
                dbg(NEIGHBOR_CHANNEL, "\tNeighbor ID: %d\n", neighbors[i]);
            }
        }
    }
}















/*
module NeighborDiscoveryP {
	provides interface NeighborDiscovery;
    uses interface Random as Random;
    uses interface Timer<TMilli> as Timer;
    uses interface Hashmap<uint32_t> as NeighborTable;
    uses interface SimpleSend as Sender;

}

implementation {
	pack sendp;
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length);

	command error_t NeighborDiscovery.start() {
        call Timer.startPeriodic(500 + (uint16_t)(call Random.rand16()%500));
        dbg(NEIGHBOR_CHANNEL, "Node %d: Began Neighbor Discovery\n", TOS_NODE_ID);
        return SUCCESS;
    }

    command void NeighborDiscovery.discover(pack* packet) {
        dbg(NEIGHBOR_CHANNEL, "In NeighborDiscovery.discover\n");

        if(packet->TTL > 0 && packet->protocol == PROTOCOL_PING) {
            dbg(NEIGHBOR_CHANNEL, "PING Neighbor Discovery\n");
            packet->TTL = packet->TTL-1;
            packet->src = TOS_NODE_ID;
            packet->protocol = PROTOCOL_PINGREPLY;
            call Sender.send(*packet, AM_BROADCAST_ADDR);
        }
        else if (packet->protocol == PROTOCOL_PINGREPLY && packet->dest == 0) {
            dbg(NEIGHBOR_CHANNEL, "PING REPLY Neighbor Discovery, Confirmed neighbor %d\n", packet->src);
            if(!call NeighborTable.contains(packet->src)) {
            }
            else {call NeighborTable.insert(packet->src, NODETIMETOLIVE);}
        }
    }

    event void Timer.fired() {
        uint32_t* neighbors = call NeighborTable.getKeys();
        uint8_t payload = 0;
        uint16_t i = 0;
        dbg(NEIGHBOR_CHANNEL, "In Timer fired\n");

        for(i = i; i<call NeighborTable.size(); i++) {
            if(neighbors[i]==0) {continue;}
            if (call NeighborTable.get(neighbors[i]) == 0) {
                dbg(NEIGHBOR_CHANNEL, "Deleted Neighbor %d\n", neighbors[i]);
                call NeighborTable.remove(neighbors[i]);
            }
            else {
                call NeighborTable.insert(neighbors[i], call NeighborTable.get(neighbors[i])-1);
            }
        }
        dbg(NEIGHBOR_CHANNEL, "In Timer fired 2\n");
        makePack(&sendp, TOS_NODE_ID, 0, 1, PROTOCOL_PING, 0, &payload, PACKET_MAX_PAYLOAD_SIZE);
        call Sender.send(sendp, AM_BROADCAST_ADDR);
    }


    command uint32_t* NeighborDiscovery.getNeighbors(){
        return call NeighborTable.getKeys();
    }

     command uint16_t NeighborDiscovery.getNeighborListSize() {
        return call NeighborTable.size();
    }


    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length) {
        dbg(NEIGHBOR_CHANNEL, "In Timer fired 3\n");
        Package->src = src; Package->dest = dest;
        Package->TTL = TTL; Package->seq = seq;
        Package->protocol = protocol;  
        memcpy(Package->payload, payload, length);
    } 

    command void NeighborDiscovery.printNeighbors() {
        uint16_t i = 0;
        uint32_t* neighbors = call NeighborTable.getKeys();  
        dbg(NEIGHBOR_CHANNEL, "Printing Neighbors:\n");
        for(i=i; i < call NeighborTable.size(); i++) {
            if(neighbors[i] != 0) {
                dbg(NEIGHBOR_CHANNEL, "\tNeighbor: %d\n", neighbors[i]);
            }
        }
    }

}
*/
