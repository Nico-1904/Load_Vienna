classdef Interference < uint32
    %INTERFERENCE enum of implemented options to mitigate interference border effects
    % In the outer ROI, border effects lead to a decrease in interference
    % (due to the lack of interference from base stations from outside of
    % the ROI), which distorts the results for users in the outer ROI.
    % These negative effects can be mitigated either by creating an
    % interference region with simplified base stations that create
    % interference coming from outside of the ROI. This setting decides
    % which strategy is used and how the users are placed in the additional
    % interference region.
    %
    % initial author: Agnes Fastenbauer
    %
    % see also parameters.regionOfInterest.RegionOfInterest.interference,
    % parameters.regionOfInterest.RegionOfInterest.interferenceRegionFactor

    enumeration
        % simulate with interference region
        % Simulate an additional interference region with simplified base
        % stations that produce interference from outside of the ROI.
        % The size of the interference region is set through the parameter
        % parameters.regionOfInterest.RegionOfInterest.interferenceRegionFactor.
        % The users in the interference region are placed by extending the
        % user placement of the ROI to the interference region.
        %
        % For this setting additional network elements are created automatically outside
        % of the ROI. Thus, users are splitted automatically between the ROI and the
        % interference region during users setup. These networkElements then use
        % a simplified scheduler and feedback and have as purpose to create
        % interference for the links at the border of the ROI.
        %
        % see also parameters.regionOfInterest.RegionOfInterest.interferenceRegionFactor
        regionContinuousUser	(1)

        % simulate with interference region
        % Simulate an additional interference region with simplified base
        % stations that produce interference from outside of the ROI.
        % The size of the interference region is set through the parameter
        % parameters.regionOfInterest.RegionOfInterest.interferenceRegionFactor.
        % The users in the interference region are placed with the user
        % creation class parameters.user.InterferenceRegion.
        %
        % For this setting additional network elements has to be placed manually outside
        % of the ROI. These networkElements then use
        % a simplified scheduler and feedback and have as purpose to create
        % interference for the links at the border of the ROI.
        %
        % see also parameters.user.InterferenceRegion,
        % parameters.regionOfInterest.RegionOfInterest.interferenceRegionFactor
        regionIndependentUser	(2)

        % simulate with wraparound
        % In the wraparound scenario, the base stations are wrapped for
        % each user. This is intended to create a borderless network in
        % which signal that leave the ROI, re-enter at the opposite edge.
        % In practice, the network is replicated along each edge and corner
        % of the ROI and for each user the closest BS-replication of each
        % BS is chosen.
        wraparound              (3)

        % simulate without any border interference strategy
        %
        % Without any border interference strategy, the users at the border
        % of the ROI will experience less interference, than the users at
        % the center of the ROI that are surrounded by interferers.
        none                    (4)
    end
end

