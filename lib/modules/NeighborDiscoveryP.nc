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
    uses interface Hashmap<uint32_t> as NeighborTable;
    uses interface SimpleSend as Sender;


}

/*
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
        dbg(NEIGHBOR_CHANNEL, "In Timer fired 2\n");//can be commented 
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
        dbg(NEIGHBOR_CHANNEL, "In Timer fired 3\n");///can be commented
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


}*/

implementation {

    // Packet variable for sending
    pack packetToSend;

    // Function to create a packet with the given parameters
    void createPacket(pack *packet, uint16_t source, uint16_t destination, uint16_t ttl, uint16_t protocolType, uint16_t sequence, uint8_t* dataPayload, uint8_t length);

    // Command to start the Neighbor Discovery process
    command error_t NeighborDiscovery.begin() {
        // Start the periodic timer with a random interval between 500ms and 1000ms
        call Timer.startPeriodic(500 + (uint16_t)(call Random.rand16() % 500));
        dbg(NEIGHBOR_CHANNEL, "Node %d: Neighbor Discovery started\n", TOS_NODE_ID);
        return SUCCESS;
    }

    // Command to handle neighbor discovery logic when a packet is received
    command void NeighborDiscovery.discover(pack* receivedPacket) {
        dbg(NEIGHBOR_CHANNEL, "NeighborDiscovery.discover called\n");

        // If TTL > 0 and it's a PING protocol, update the packet and send a reply
        if(receivedPacket->TTL > 0 && receivedPacket->protocol == PROTOCOL_PING) {
            dbg(NEIGHBOR_CHANNEL, "PING received, performing Neighbor Discovery\n");
            receivedPacket->TTL--;
            receivedPacket->src = TOS_NODE_ID;
            receivedPacket->protocol = PROTOCOL_PINGREPLY;
            call Sender.send(*receivedPacket, AM_BROADCAST_ADDR);
        }
        // If it's a PING reply and the destination is 0, confirm the neighbor
        else if (receivedPacket->protocol == PROTOCOL_PINGREPLY && receivedPacket->dest == 0) {
            dbg(NEIGHBOR_CHANNEL, "PING REPLY received, Neighbor confirmed: %d\n", receivedPacket->src);
            if (!call NeighborTable.contains(receivedPacket->src)) {
                call NeighborTable.insert(receivedPacket->src, NODETIMETOLIVE); // Add neighbor if not already present
            }
        }
    }

    // Timer event fired periodically to manage neighbors and send discovery packets
    event void Timer.onTimerFired() {
        uint32_t* neighborList = call NeighborTable.getKeys(); // Get all neighbors
        uint8_t packetPayload = 0;
        uint16_t idx = 0;
        dbg(NEIGHBOR_CHANNEL, "Timer event fired, processing neighbors\n");

        // Iterate through the neighbor table and decrement TTL for each neighbor
        for (idx = idx; idx < call NeighborTable.size(); idx++) {
            if (neighborList[idx] == 0) { continue; } // Skip empty entries
            if (call NeighborTable.get(neighborList[idx]) == 0) {
                dbg(NEIGHBOR_CHANNEL, "Removing expired neighbor: %d\n", neighborList[idx]);
                call NeighborTable.remove(neighborList[idx]); // Remove neighbors with TTL = 0
            } else {
                call NeighborTable.insert(neighborList[idx], call NeighborTable.get(neighborList[idx]) - 1); // Decrement TTL
            }
        }
        
        dbg(NEIGHBOR_CHANNEL, "Sending new neighbor discovery packet\n");
        createPacket(&packetToSend, TOS_NODE_ID, 0, 1, PROTOCOL_PING, 0, &packetPayload, PACKET_MAX_PAYLOAD_SIZE);
        call Sender.send(packetToSend, AM_BROADCAST_ADDR); // Broadcast discovery packet
    }

    // Command to return the list of neighbor IDs
    command uint32_t* NeighborDiscovery.getNeighborIDs() {
        return call NeighborTable.getKeys(); // Return the keys (neighbor IDs)
    }

    // Command to return the size of the neighbor table
    command uint16_t NeighborDiscovery.getNeighborCount() {
        return call NeighborTable.size(); // Return the number of neighbors
    }

    // Function to create a packet by assigning its fields
    void createPacket(pack *packet, uint16_t source, uint16_t destination, uint16_t ttl, uint16_t protocolType, uint16_t sequence, uint8_t* dataPayload, uint8_t length) {
        dbg(NEIGHBOR_CHANNEL, "Creating packet in NeighborDiscovery\n");
        packet->src = source;
        packet->dest = destination;
        packet->TTL = ttl;
        packet->seq = sequence;
        packet->protocol = protocolType;
        memcpy(packet->payload, dataPayload, length); // Copy the payload into the packet
    }

    // Command to print the list of neighbors (for debugging purposes)
    command void NeighborDiscovery.showNeighbors() {
        uint16_t index = 0;
        uint32_t* neighbors = call NeighborTable.getKeys();
        dbg(NEIGHBOR_CHANNEL, "Neighbors:\n");
        for (index = index; index < call NeighborTable.size(); index++) {
            if (neighbors[index] != 0) {
                dbg(NEIGHBOR_CHANNEL, "\tNeighbor ID: %d\n", neighbors[index]);
            }
        }
    }
}
