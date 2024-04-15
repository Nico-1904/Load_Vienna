classdef myColors
    %COLORS defines RGB values for various colors

    methods (Static)
        function blue = matlabBlue()
            blue = [0, 0.4470, 0.7410];
        end

        function orange = matlabOrange()
            orange = [0.8500, 0.3250, 0.0980];
        end

        function yellow = matlabYellow()
            yellow = [0.9290, 0.6940, 0.1250];
        end

        function purple = matlabPurple()
            purple = [0.4940, 0.1840, 0.5560];
        end

        function green  = matlabGreen()
            green = [0.4660, 0.6740, 0.1880];
        end

        function darkGreen = darkGreen()
            darkGreen = [0, 0.5430, 0];
        end

        function lightBlue = matlabLightBlue()
            lightBlue = [0.3010, 0.7450, 0.9330];
        end

        function red = matlabRed()
            red = [0.6350, 0.0780, 0.1840];
        end

        function white = white()
            white = [1, 1, 1];
        end

        function black = black()
            black = [0, 0, 0];
        end

        function gray = gray()
            gray = [0.5, 0.5, 0.5];
        end

        function lightGray = lightGray()
            lightGray = [0.75, 0.75, 0.75];
        end

        function darkGray = darkGray()
            darkGray = [0.25, 0.25, 0.25];
        end
    end
end

