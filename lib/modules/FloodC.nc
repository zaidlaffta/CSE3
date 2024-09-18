module FloodC {  
    uses interface Boot;  
    uses interface Packet;  
    uses interface AMSend;  
    uses interface Receive;  
    uses interface Timer<TMilli> as FloodTimer;  
  
    uint8_t receivedMessages[128]; // For simplicity, fixed-size array to store received message IDs  
    uint8_t messageCount = 0;  
    message_t packet;  
  
    event void Boot.booted() {  
        call FloodTimer.startPeriodic(1000); // Start a periodic timer  
    }  
  
    event void FloodTimer.fired() {  
        // Code to send a flood message periodically  
        uint8_t* payload = call Packet.getPayload(&packet, sizeof(uint8_t));  
        if (payload == NULL) return;  
        *payload = TOS_NODE_ID;  
        call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(uint8_t));  
    }  
  
    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {  
        uint8_t receivedMessage = *((uint8_t*)payload);  
        for (uint8_t i = 0; i < messageCount; i++) {  
            if (receivedMessages[i] == receivedMessage) return msg; // Already received  
        }  
        receivedMessages[messageCount++] = receivedMessage;  
        call AMSend.send(AM_BROADCAST_ADDR, msg, len); // Forward the message  
        return msg;  
    }  
  
    event void AMSend.sendDone(message_t* msg, error_t error) {  
        // Handle send completion  
    }  
}  
