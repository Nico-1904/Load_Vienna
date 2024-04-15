% +USER
% This package contains the user creation functions and parameter sets.
% To create users add a parameter file from this package to the
% params.userParameters container in the scenario file. The user will then
% be generated in simulation.SimulationSetup.createUsers
%
% see also simulation.SimulationSetup.createUsers, networkElements.ue.User,
% parameters.Parameters.userParameters
%
% Files
%   ClusterSuperclass   - superclass for clustered distributions
%   GaussCluster        - a parameter class for base stations with clustered antennas
%   InterferenceRegion  - places users in the interference region
%   Parameters          - superclass of all user scenario parameters
%   Poisson2D           - configures a static user placement scenario according to a PPP
%   PoissonStreets      - creates users randomly and statically placed on streets
%   PredefinedPositions - places users on predefined positions
%   UniformCluster      - places users in uniform circular clusters
%
% Packages
%   +trafficModel       - traffic model parameters

