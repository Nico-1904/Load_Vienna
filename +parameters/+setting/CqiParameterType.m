classdef CqiParameterType < uint32
    %CQIPARAMETERTYPE enum of implemented CQI types
    %
    %NOTE: in parameters.transmissionParameters same CQI types but without
    %calibration parameters are implemented. They are not yet listed here.
    %
    % CQI:  channel quality indicator
    %
    % initial author: Agnes Fastenbauer
    % extended by: Thomas Lipovec, added entries for Table 2 and 4 in TS 36.213
    %
    % see also parameters.transmissionParameters.CqiParameters

    enumeration
        % CQI mapping according to TS 36.213 V13.2.0 (2016-06) (i.e., Table 7.2.3-1)
        % Based on QPSK, 16QAM and 64QAM
        % see also parameters.transmissionParameters.LteCqiParametersTS36213NonBLCEUE1
        Cqi64QAM	(1)

        % CQI mapping according to TS 36.213 V15.8.0 (2020-02) (i.e., Table 7.2.3-2)
        % Based on QPSK, 16QAM, 64QAM and 256QAM
        % see also parameters.transmissionParameters.LteCqiParametersTS36213NonBLCEUE2
        Cqi256QAM	(2)

        % CQI mapping according to TS 36.213 V15.8.0 (2020-02) (i.e., Table 7.2.3-4)
        % Based on QPSK, 16QAM, 64QAM, 256QAM and 1024QAM
        % see also parameters.transmissionParameters.LteCqiParametersTS36213NonBLCEUE4
        Cqi1024QAM	(3)
    end
end

