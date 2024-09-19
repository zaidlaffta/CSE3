
//CSE160
//Project 1
interface NeighborDiscovery {
	// Starts the neighbor discovery process. This could involve broadcasting
	command void start();

	// Outputs information about the current state of the neighbor discovery process.
	command void print();

	// Handles an incoming message from a neighboring node. 
	command void neighborReceived(pack *myMsg);
}
