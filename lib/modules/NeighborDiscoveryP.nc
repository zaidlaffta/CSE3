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
    
    pack outgoingPacket;                     // Renamed sendp for clarity

    // Helper function to construct a packet
    void constructPacket(pack *pkt, uint16_t srcID, uint16_t destID, uint16_t ttlValue, uint16_t protocolType, uint16_t seqNum, uint8_t* dataPayload, uint8_t payloadSize);

    // Command to start the Neighbor Discovery process
    command error_t NeighborDiscovery.start() {
        call Timer.startPeriodic(500 + (uint16_t)(call Random.rand16()%500));  // Start a timer with a random delay
        dbg(NEIGHBOR_CHANNEL, "Node %d: Neighbor Discovery Initialized\n", TOS_NODE_ID);
        return SUCCESS;
    }

    // Command to handle the discovery of neighbors
    command void NeighborDiscovery.initiateDiscovery(pack* incomingPacket) {
        dbg(NEIGHBOR_CHANNEL, "Executing NeighborDiscovery.initiateDiscovery\n");

        // Check if packet is a PING and has a valid TTL
        if (incomingPacket->TTL > 0 && incomingPacket->protocol == PROTOCOL_PING) {
            dbg(NEIGHBOR_CHANNEL, "Handling PING in Neighbor Discovery\n");
            incomingPacket->TTL -= 1;                            // Decrement TTL
            incomingPacket->src = TOS_NODE_ID;                   // Set source as the current node
            incomingPacket->protocol = PROTOCOL_PINGREPLY;        // Change protocol to PINGREPLY
            call Sender.send(*incomingPacket, AM_BROADCAST_ADDR); // Send the modified packet
        }
        // Check if packet is a PINGREPLY and the destination is 0 (broadcast)
        else if (incomingPacket->protocol == PROTOCOL_PINGREPLY && incomingPacket->dest == 0) {
            dbg(NEIGHBOR_CHANNEL, "Received PINGREPLY, Neighbor %d Confirmed\n", incomingPacket->src);
            if (!call NeighborTable.contains(incomingPacket->src)) {
                call NeighborTable.insert(incomingPacket->src, NODETIMETOLIVE);  // Add neighbor to table if not already present
            }
        }
    }

    // Event triggered when Timer fires
    event void Timer.fired() {
        uint32_t* neighborList = call NeighborTable.getKeys();  // Get list of neighbors
        uint8_t data = 0;                                       // Dummy payload data
        uint16_t index = 0;                                     // Index for iterating through neighbors
        dbg(NEIGHBOR_CHANNEL, "Timer Fired, Checking Neighbors\n");

        // Iterate over neighbors in the NeighborTable
        for (index = index; index < call NeighborTable.size(); index++) {
            if (neighborList[index] == 0) continue;              // Skip empty entries
            if (call NeighborTable.get(neighborList[index]) == 0) {
                dbg(NEIGHBOR_CHANNEL, "Removing Neighbor %d\n", neighborList[index]);  // Remove neighbor if TTL is zero
                call NeighborTable.remove(neighborList[index]);   // Remove neighbor from table
            } else {
                call NeighborTable.insert(neighborList[index], call NeighborTable.get(neighborList[index])-1); // Decrement TTL
            }
        }
        dbg(NEIGHBOR_CHANNEL, "Timer Fired, Neighbor Check Complete\n");

        // Construct a new PING packet and send it
        constructPacket(&outgoingPacket, TOS_NODE_ID, 0, 1, PROTOCOL_PING, 0, &data, PACKET_MAX_PAYLOAD_SIZE);
        call Sender.send(outgoingPacket, AM_BROADCAST_ADDR);  // Broadcast packet
    }

    // Command to return a list of neighbors
    command uint32_t* NeighborDiscovery.getNeighborKeys() {
        return call NeighborTable.getKeys();
    }

    // Command to return the size of the neighbor list
    command uint16_t NeighborDiscovery.getNeighborCount() {
        return call NeighborTable.size();
    }

    // Helper function to create a packet
    void constructPacket(pack *pkt, uint16_t srcID, uint16_t destID, uint16_t ttlValue, uint16_t protocolType, uint16_t seqNum, uint8_t* dataPayload, uint8_t payloadSize) {
        dbg(NEIGHBOR_CHANNEL, "Constructing Packet\n");
        pkt->src = srcID; 
        pkt->dest = destID;
        pkt->TTL = ttlValue; 
        pkt->seq = seqNum;
        pkt->protocol = protocolType;  
        memcpy(pkt->payload, dataPayload, payloadSize);  // Copy the payload into the packet
    } 

    // Command to print the current list of neighbors
    command void NeighborDiscovery.displayNeighbors() {
        uint16_t index = 0;
        uint32_t* neighborList = call NeighborTable.getKeys();  // Get neighbor keys
        dbg(NEIGHBOR_CHANNEL, "Neighbor List:\n");

        // Loop through neighbors and print each one
        for (index = index; index < call NeighborTable.size(); index++) {
            if (neighborList[index] != 0) {
                dbg(NEIGHBOR_CHANNEL, "\tNeighbor: %d\n", neighborList[index]);
            }
        }
    }
}