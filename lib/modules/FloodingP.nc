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
    uses interface Timer<TMilli> as PrintTimer;

}
implementation {
	pack sendPackage;
    uint16_t floodedPacketCount = 0;  // Counter for flooded packets
	uint16_t sequenceNum = 0;

	

    bool containsval(uint32_t key, uint32_t val) {
    	if(call PreviousPackets.contains(key)) {
    		if(call PreviousPackets.get(key) == val) {
    			return TRUE;
    		}
    	}
        return FALSE;

    }
    //function to make a packet extracted from Node.nc file
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length) {
        //set source node ID
        Package->src = src;
        //set Node destination ID
        Package->dest = dest;
        //Set time to live
        Package->TTL = TTL;
        //Set sequence number
        Package->seq = seq;
        //Set protocol type
        Package->protocol = protocol;
        //Copy payload into the packet
        memcpy(Package->payload, payload, length);
    }
    uint16_t getFloodedPacketCount() {
        return floodedPacketCount;
    }

    command void Flooding.ping(uint16_t destination, uint8_t *payload) {
        dbg(FLOODING_CHANNEL, "PING EVENT \n");
        dbg(FLOODING_CHANNEL, "SENDER %d\n", TOS_NODE_ID);
        dbg(FLOODING_CHANNEL, "DEST %d\n", destination);
        makePack(&sendPackage, TOS_NODE_ID, destination, 22, PROTOCOL_PING, sequenceNum, payload, PACKET_MAX_PAYLOAD_SIZE);
        call packetTransmitter.send(sendPackage, AM_BROADCAST_ADDR);
        sequenceNum++;
    }

/*
    command error_t Flooding.start() {
    call PrintTimer.startPeriodic(500); // Print every 500 ms 
    return SUCCESS;
    }
*/

    command void Flooding.Flood(pack* letter){                                 
        if(containsval(letter -> seq, letter -> src)){
            dbg(FLOODING_CHANNEL, "Duplicate packet. Will not forward...\n");           
        } else if(letter -> TTL == 0) {                                                 
            dbg(FLOODING_CHANNEL, "Packet has expired. Will not forward to prevent infinite loop...\n");
        } else if(letter -> dest ==  TOS_NODE_ID){
            if(letter -> protocol == PROTOCOL_PING){                                    
                dbg(FLOODING_CHANNEL, "Package has reached the destination!...\n");

                call PreviousPackets.insert(letter -> seq, letter -> src);           
                makePack(&sendPackage, letter -> dest, letter -> src, 10, PROTOCOL_PINGREPLY, sequenceNum++, (uint8_t *) letter -> payload, PACKET_MAX_PAYLOAD_SIZE);     //RePacket to send to subsequent nodes
                call packetTransmitter.send(sendPackage, AM_BROADCAST_ADDR);                      
                dbg(FLOODING_CHANNEL, "RePackage has been resent!...\n");               
            } else if(letter -> protocol == PROTOCOL_PINGREPLY){
                dbg(FLOODING_CHANNEL, "RePackage has reached destination...\n");
                call PreviousPackets.insert(letter -> seq, letter -> src);           
            }
        } else {
            //reduce time to live
            letter -> TTL--;                                                         
            
            call PreviousPackets.insert(letter -> seq, letter -> src);               
            call packetTransmitter.send(*letter, AM_BROADCAST_ADDR);
            floodedPacketCount++;
            dbg(FLOODING_CHANNEL, "Floodpacket count is %d \n", floodedPacketCount);                               

            dbg(FLOODING_CHANNEL, "New package has been forwarded with new Time To Live...\n"); //
        }
    }
    if (letter->TTL == 0) {
    dbg(GENERAL_CHANNEL, "Packet will be dropped as TTL is 0\n");  // Correct message formatting
    dbg(FLOODING_CHANNEL, "Periodic Report: Total Flooded Packets: %d\n", floodedPacketCount);  // Correct debug message format
    return;  // Exit the function to drop the packet
}


}