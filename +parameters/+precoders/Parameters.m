classdef Parameters < tools.HiddenHandle
    %PARAMETERS Superclass for precoder parameters
    % The baseband precoder  maps the layers (or user streams) to RF chains
    % for each resource block individually.
    % For each base station a downlink and uplink precoder can be
    % specified.
    %
    % see also: parameters.basestation.Parameters, precoders.Precoder
    % initial author: Alexander Bokor

    methods (Abstract)
        % Generate a precoder object for the given transmission parameters.
        %
        % input:
        %   transmissionParameters: [1x1]handleObject parameters.transmissionParameters.TransmissionParameters
        %   baseStations:           [1xnBs]handleObject networkElements.bs.BaseStation
        %   networkElements.bs.BaseStation base stations used with this
        %   precoder
        %
        % output:
        %   obj: [1x1]handleObject precoders.Precoder
        %
        % see also: parameters.precoders
        precoder = generatePrecoder(obj, transmissionParameters, baseStations)

        % Checks if parameters are valid for this precoder type.
        %
        % input:
        %   transmissionParameters: [1x1]handleObject parameters.transmissionParameters.TransmissionParameters
        %   baseStations:           [1xnBs]handleObject networkElements.bs.BaseStation
        %
        % output:
        %   isValid: [1x1]logical true if parameters are valid for this precoder
        %
        % see also: parameters.precoders
        isValid = checkConfig(obj, transmissionParameters, baseStations)
    end
end

