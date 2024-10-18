# 5G-based System-level Integrated Sensing and Communication Simulator
## STILL UNDER DEVELOPING and DEBUGGING
## NOTE: R2023a or above is NOT available for this simulator

## Incooperates the following parts:<br>
###  Scenario generation,<br>
    Based on the OpenStreetMap™ open-source data
###  Multi-node ISAC network simulation,<br>
    Focus on implementing key techniques of ISAC
###  Communication simulation functions (MIMO), including:<br>
    APP layers modeling
    RLC layers modeling
    MAC layers modeling
    PHY layers modeling
    CDL channel modeling
    Pathloss modeling
    Simulation visualization tools
### Sensing simulation functions (mono-static sensing), including:<br>
    Echo modeling
    Mono-static sensing modeling
    Detection algorithms (2D-CFAR)
    Estimation algorithms (2D-FFT and MUSIC)


### Initial members participated in this project:<br>
    D. Xue, J. Wei, Y. Li, T. Zeng,
    Beijing University of Posts and Telecommunications,
    Beijing, P. R. China.


## MATLAB version and toolboxes required: 
    R2019(not tested)-R2022, (IMPORTANT NOTE: R2023a and above is not available!) 
    5G Toolbox, Phased Array System Toolbox, Wireless Communication Toolbox.


## Getting Started
    To simulate the system-level ISAC scenario,
    first, deploy the scenario in the 'scenarios' folder,
    and then locate the corresponding file name in the 'launcherFiles' folder to run the simulation.


## Documentation
    None at present.


## License
    Copyright (C) 2023 Beijing University of Posts and Telecommunications
    All rights reserved.

    System-level ISAC Simulator
    Author: D. Xue, et.al.


## Contact
    li-yonggang@bupt.edu.cn (currently in charge)


## 3GPP Standards:
    3GPP TS 38.211(Physical channels and modulation),
    3GPP TS 38.212(Multiplexing and channel coding),
    3GPP TS 38.213(Physical layer procedures for control),
    3GPP TS 38.214(Physical layer procedures for data),
    3GPP TR 38.901(Study on channel model for frequencies from 0.5 to 100 GHz). 

