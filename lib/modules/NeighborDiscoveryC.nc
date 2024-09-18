module NeighborDiscoveryC {  
    uses interface Boot;  
    uses interface Packet;  
    uses interface AMSend;  
    uses interface Receive;  
    uses interface Timer<TMilli> as NeighborTimer;  
  
    uint8_t neighbors[128]; // For simplicity, fixed-size array to store neighbor IDs  
    uint8_t neighborCount = 0;  
    message_t packet;  
  
    event void Boot.booted() {  
        call NeighborTimer.startPeriodic(2000); // Start a periodic timer  
    }  
  
    event void NeighborTimer.fired() {  
        // Code to send a neighbor discovery message periodically  
        uint8_t* payload = call Packet.getPayload(&packet, sizeof(uint8_t));  
        if (payload == NULL) return;  
        *payload = TOS_NODE_ID;  
        call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(uint8_t));  
    }  
  
    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {  
        uint8_t receivedNeighbor = *((uint8_t*)payload);  
        for (uint8_t i = 0; i < neighborCount; i++) {  
            if (neighbors[i] == receivedNeighbor) return msg; // Already received  
        }  
        neighbors[neighborCount++] = receivedNeighbor;  
        return msg;  
    }  
  
    event void AMSend.sendDone(message_t* msg, error_t error) {  
        // Handle send completion  
    }  
}  
