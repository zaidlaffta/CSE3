module FloodC {
    uses {
        interface AMSend;
        interface Receive;
        interface Boot;
        interface Timer<TMilli>;
    }
}

implementation {
    event void Boot.booted() {
        call Timer.startPeriodic(1000);  // Send every 1 second
    }

    event void Timer.fired() {
        message_t msg;
        // Construct the message for flooding
        call AMSend.send(AM_BROADCAST_ADDR, &msg, sizeof(msg)); // Broadcast
    }

    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
        // Process received flood message
        return msg;
    }
}
