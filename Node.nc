// Project 1
// CSE 160
// Sep/28/2024
// Zaid Laffta

/*
 * ANDES Lab - University of California, Merced
 * Basic network node functions with LinkStateRouting integration.
 */

#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"

module Node {
   uses interface Boot;
   uses interface SplitControl as AMControl;
   uses interface Receive;
   uses interface SimpleSend as Sender;
   uses interface CommandHandler;
   uses interface NeighborDiscovery;
   uses interface LinkStateRouting;
}

implementation {
   pack sendPackage;

   event void Boot.booted() {
      call AMControl.start();
      dbg(GENERAL_CHANNEL, "Booted\\n");
   }

   event void AMControl.startDone(error_t err) {
      if (err == SUCCESS) {
         dbg(GENERAL_CHANNEL, "Radio On\\n");
      } else {
         call AMControl.start();
      }
   }

   event void AMControl.stopDone(error_t err) {}

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
      dbg(GENERAL_CHANNEL, "Packet Received\\n");
      if (len == sizeof(pack)) {
         pack* myMsg = (pack*) payload;
         dbg(GENERAL_CHANNEL, "Package Payload: %s\\n", myMsg->payload);
         return msg;
      }
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\\n", len);
      return msg;
   }

   event void CommandHandler.ping(uint16_t destination, uint8_t* payload) {
      dbg(GENERAL_CHANNEL, "PING EVENT \\n");
      makePack(&sendPackage, TOS_NODE_ID, destination, 0, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      call Sender.send(sendPackage, destination);
   }

   event void CommandHandler.printLinkState() {
      call LinkStateRouting.printLinkStateInfo();
   }

   event void NeighborDiscovery.neighborAdded(uint16_t neighbor) {
      dbg(GENERAL_CHANNEL, "Neighbor added: %u\\n", neighbor);
      call LinkStateRouting.updateRoutingTable(neighbor);
   }

   event void NeighborDiscovery.neighborRemoved(uint16_t neighbor) {
      dbg(GENERAL_CHANNEL, "Neighbor removed: %u\\n", neighbor);
   }
}
