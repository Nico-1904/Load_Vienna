classdef SaveObject < tools.HiddenHandle
    %SaveObject list of additional results and settings to save
    % SaveObject is a parameter object that tells the simulation what
    % additional results should be saved in the result file for further
    % processing. By default everything is set to false, if additional
    % parameters are to be saved, they have to be specified here.
    %
    % Saving a city to a file can be enabled in parameters.city.Parameters.
    %
    % initial author: Lukas Nagel
    %
    % see also simulation.results.ResultsFull.additional,
    % simulation.postprocessing.PostprocessorSuperclass.extractAdditionalResults,
    % parameters.Parameters.save

    properties
        % LOS information
        % [1x1]logical flag for saving LOS/NLOS-map
        % Saves the LOS map, that indicates for all walls if they block a
        % link for each user-antenna link.
        %
        % see also simulation.ChunkSimulation.blockageMapUserAntennas
        losMap = false;

        % indoor/outdoor information
        % [1x1]logical flag for saving indoor/outdoorMap
        % Saves indoor/outdoor information for all users in all slots.
        %
        % see also simulation.ChunkSimulation.isIndoor
        isIndoor = false;

        % mapping of the bs/antenna to antenna numbering
        % [1x1]logical flag for saving antenna to base station mapper
        % Saves the antenna-BS mapper. Note that this information is saved,
        % if the network is saved, since the base stations are saved with
        % their attached antennas.
        %
        % see also simulation.ChunkConfig.antennaBsMapper,
        % tools.AntennaBsMapper
        antennaBsMapper = false;

        % table with macroscopic fading
        % [1x1]logical flag for saving macroscopic fading
        % Saves the macroscopic fading for each link. The macroscopic
        % fading consists of antenna gain, path loss, shadowing and wall
        % loss. The minimum coupling loss is already applied to this value.
        %
        % see also simulation.ChunkSimulation.macroscopicFadingdB
        macroscopicFading = false;

        % table with wall loss
        % [1x1]logical flag for saving wall loss for each link
        % Saves the wall loss for each link and each segment.
        %
        % see also simulation.ChunkSimulation.wallLossdB
        wallLoss = false;

        % table with sahdow fading
        % [1x1]logical flag for saving shadow fading for each link
        % Saves the shadow fading for each link and each segment.
        %
        % see also simulation.ChunkSimulation.shadowFadingdB
        shadowFading = false;

        % table with antenna gain
        % [1x1]logical flag for saving antanna gain for each link
        % Saves the antanna gain for each link and each segment.
        %
        % see also simulation.ChunkSimulation.antennaGaindB
        antennaGain = false;

        % table with receive power
        % [1x1]logical flag for saving receive power for each link
        % Saves the receive power for each link and each segment.
        %
        % see also simulation.ChunkSimulation.receivePowerdB
        receivePower = false;

        % table of all pathlosses
        % [1x1]logical flag for saving pathloss table
        % Saves the pathloss table for all links in all segments.
        %
        % see also simulation.ChunkSimulation.pathLossTableDL
        pathlossTable = false;

        % save feedback per user per slot
        % [1x1]logical flag for saving feedback
        %
        % see also feedback.Feedback
        feedback = false;

        % save DL scheduler signaling per user per slot
        % [1x1]logical flag for saving scheduler signaling
        %
        % see also scheduler.signaling.UserScheduling
        userScheduling = false;
    end
end

