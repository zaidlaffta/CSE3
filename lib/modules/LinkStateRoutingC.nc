// Project 1
// CSE 160
// LinkStateRoutingC.nc
// Sep/28/2024
// Zaid Laffta

configuration LinkStateRoutingC {
    provides interface LinkStateRouting;
}

implementation {
    // Wiring the LinkStateRouting interface to the module
    components LinkStateRoutingP as LSRP;
    LinkStateRouting = LSRP;
}
