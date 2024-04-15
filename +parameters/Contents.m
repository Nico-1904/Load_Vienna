% +PARAMETERS
%
% This packages defines all parameters used in a simulation.
% The subpackages basestation and user define the parameters of the network
% elements created for a simulation.
% Subpackages building, city and wall define the parameters of the
% blockages created for a simulation.
% Subpackage regionOfInterest defines the simualtion region.
% Subpackages resourceGrid and transmissionParameters define transmission
% parameters and the use of physical resources (e.g. resource grid size,
% layer mapping, ...).
% Subpackage setting collects and defines setting options that can be made
% for a simulation.
% Check out the parameter files to find the default values of the different
% parameters.
%
% see also parameters.basestation, parameters.building, parameters.city,
% parameters.user, parameters.WallBlockage, parameters.resourceGrid,
% parameters.transmissionParameters, parameters.setting
%
% Files
%   Parameters                  - main class where all parameters are defined
%   +basestation                - creation functions for base stations and antennas
%   +building                   - creation functions for buildings
%   +channelModel               - Quadriga channel model parameters
%   +city                       - creation functions for cities (with streets)
%   +indoorDecision             - idoor/outdoor decision functions
%   +pathlossParameters         - path loss model parameters
%   +precoders                  - precoder parameters
%   +regionOfInterest           - region of interest and interference region parameters
%   +resourceGrid               - physical resource grid settings and parameters
%   +setting                    - different model and setting options
%   +transmissionParameters	    - settings concerning transmission schemes
%   +user                       - creation functions for users
%   +wallBlockage               - creation functions for wall blockages
%   Carrier                     - component carrier information
%   Constants                   - physical constants
%   Noma                        - parameters for NOMA transmission
%   PathlossModelContainer      - maps link types to pathloss models
%   SaveObject                  - SaveObject list of additional results and settings to save
%   SchedulerParameters         - scheduler settings
%   ShadowFadingParameters      - shadow fading settings
%   SmallScaleParameters        - small scale fading parameters
%   SpectrumSchedulerParameters - SpectrumSchedulerParameters spectrum scheduler settings
%   Time                        - parameters needed to define the timeline

