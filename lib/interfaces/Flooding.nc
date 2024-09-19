//CSE160
//Project 1
interface Flooding {
	// Sends a ping message to the specified destination node.
	command void ping(uint16_t destination, uint8_t *payload);

	// Initiates a flooding operation, where 'myMsg' (a pointer to a packet structure) 
	command void Flood(pack* myMsg);
}
