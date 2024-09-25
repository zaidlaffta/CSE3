//CSE160
//Project 1

#include "../../includes/channels.h"
#include "../../includes/CommandMsg.h"
#include "../../includes/packet.h"
#include "../../includes/protocol.h"
#include "../../includes/sendInfo.h"

#define TTL_COMPARE = -500;

module FloodingP {
    // This module provides the Flooding interface, allowing other modules to access
	provides interface Flooding;
    // This module uses the SimpleSend interface as packet Transmitter
	uses interface SimpleSend as packetTransmitter;
    // This module uses the Hashmap interface with uint32_t keysw which t oprevent packet send previously
	uses interface Hashmap<uint32_t> as PreviousPackets;
    //timer to print number of flooding packets

}
implementation {
    
    uint16_t totalFloodedPackets = 0;       // Counter for tracking flooded packets
    uint16_t currentSeqNum = 0;             // Sequence number for packet identification
    pack packetToSend;                      // Renamed for better clarity

    // Function to check if a key-value pair exists in the PreviousPackets hashmap
    bool isPacketPreviouslySent(uint32_t key, uint32_t val) {
        if (call PreviousPackets.contains(key)) {        // Check if the key exists
            if (call PreviousPackets.get(key) == val) {  // Verify the value associated with the key
                return TRUE;                             // Return true if both match
            }
        }
        return FALSE;                                    // Otherwise, return false
    }

    // Function to create a packet based on input parameters
    void createPacket(pack *packet, uint16_t src, uint16_t dest, uint16_t ttl, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length) {
        // Set various fields of the packet structure
        packet->src = src;                            
        packet->dest = dest;                          
        packet->TTL = ttl;                               
        packet->seq = seq;                              
        packet->protocol = protocol;                   
        memcpy(packet->payload, payload, length);        
    }

    // Function to get the total number of flooded packets
    uint16_t getTotalFloodedPackets() {
        return totalFloodedPackets;
    }

    //Reset the total flooded packets counter
    void resetFloodedPacketCounter() {
        totalFloodedPackets = 0;                         // Reset the counter to 0
        dbg(FLOODING_CHANNEL, "Flooded packet counter reset to 0\n");  // Debug message
    }

    // Log the current sequence number for debugging
    void printCurrentSeqNum() {
        dbg(FLOODING_CHANNEL, "Current sequence number: %d\n", currentSeqNum); // Debug message
    }

    // Command to handle the ping event
    command void Flooding.ping(uint16_t destination, uint8_t *payload) {
        // Debugging information to show event details
        dbg(FLOODING_CHANNEL, "PING event triggered\n");
        dbg(FLOODING_CHANNEL, "Sender Node: %d\n", TOS_NODE_ID);
        dbg(FLOODING_CHANNEL, "Destination Node: %d\n", destination);
        // Create a new packet with specific parameters and send it
        createPacket(&packetToSend, TOS_NODE_ID, destination, 22, PROTOCOL_PING, currentSeqNum, payload, PACKET_MAX_PAYLOAD_SIZE);
        call packetTransmitter.send(packetToSend, AM_BROADCAST_ADDR);
        // Increment sequence number after sending
        currentSeqNum++;                                 
    }

    // Command to flood a packet through the network
    command void Flooding.Flood(pack* incomingPacket) {
        // Check if the packet was already forwarded previously
        if (isPacketPreviouslySent(incomingPacket->seq, incomingPacket->src)) {
            dbg(FLOODING_CHANNEL, "Duplicate packet detected, not forwarding\n");
        } 
        // If TTL (Time to Live) is 0, the packet should not be forwarded
        else if (incomingPacket->TTL == 0) {
            dbg(FLOODING_CHANNEL, "Packet TTL expired, not forwarding \n");
        } 
        // If the packet has reached its destination
        else if (incomingPacket->dest == TOS_NODE_ID) {
            // Handle ping protocol
            if (incomingPacket->protocol == PROTOCOL_PING) {
                dbg(FLOODING_CHANNEL, "Packet reached destination\n");
                call PreviousPackets.insert(incomingPacket->seq, incomingPacket->src);
                // Create a reply packet and send it back
                createPacket(&packetToSend, incomingPacket->dest, incomingPacket->src, 10, PROTOCOL_PINGREPLY, currentSeqNum++, (uint8_t *) incomingPacket->payload, PACKET_MAX_PAYLOAD_SIZE);
                call packetTransmitter.send(packetToSend, AM_BROADCAST_ADDR);
                dbg(FLOODING_CHANNEL, "Reply packet sent\n");
            } 
            // Handle ping reply protocol
            else if (incomingPacket->protocol == PROTOCOL_PINGREPLY) {
                dbg(FLOODING_CHANNEL, "Ping reply received at destination\n");
                call PreviousPackets.insert(incomingPacket->seq, incomingPacket->src);
            }
        } 
        // Otherwise, forward the packet to the next node
        else {
            incomingPacket->TTL--;                       // Decrease TTL to avoid infinite forwarding
            call PreviousPackets.insert(incomingPacket->seq, incomingPacket->src);
            call packetTransmitter.send(*incomingPacket, AM_BROADCAST_ADDR);
            totalFloodedPackets++;                       // Increment the flooded packet count

            // Print debug messages for tracking
            dbg(FLOODING_CHANNEL, "Total flooded packets: %d\n", totalFloodedPackets);
            dbg(FLOODING_CHANNEL, "Packet forwarded with reduced TTL\n");
        }
    }
}
