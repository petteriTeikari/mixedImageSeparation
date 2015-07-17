% Wrapper for fastICA/arabica for image data
function main_separateMixedImages_fastICA(im)
    
    % See e.g.
    % Guest Editorial - Special Issue: Latent variable analysis and signal separation
    % V. Vignerona, V. Zarzosob, R. Gribonvalc, E. Vincentc
    % http://dx.doi.org.libproxy.aalto.fi/10.1016/j.sigpro.2012.01.001

    if nargin == 0
        
        % Test locally the fastICA
        path = 'testImages';
        
        % in order of "signal strength'
        % ordinary TIFFs, not OME-TIFF   
        file{1} = 'postTreatment_with_redDrug_200um stack_slice47_ch2_clean.tif'; % green channel
        file{2} = 'postTreatment_with_redDrug_200um stack_slice47_ch3_mixed.tif'; % red channel
        file{3} = 'postTreatment_with_redDrug_200um stack_slice47_ch1_noiseChannel.tif'; % blue channel, only noise
        rgbOrder = [2 1 3];
        
        % IMPORT
     
        im = cell(length(file),1);
        for i = 1 : length(file)
            im{i} = imread(fullfile(path, file{i}));
            im{i} = double(im{i}) / 4095;
            % scale, input is 12-bit (in 16-bit TIFF though)
            % taken from .OIB file 
        end
                 
    else
        % input arguments 
    end 
    
    % Location of FastICA toolbox and arabica toolbox                    
    arabica_folder = 'arabica'; addpath(genpath(arabica_folder)); 
        
    close all
    scrsz = get(0,'ScreenSize'); % get screen size for plotting
    
    
    %% PLOT INPUT
    
        % plot    
        plotInput = false;
        if plotInput
            fig = figure('Name', 'Input'); rows = 1; cols = 2;
                set(fig,  'Position', [0.4*scrsz(3) 0.325*scrsz(4) 0.6*scrsz(3) 0.60*scrsz(4)])
            i = 1; sp(i) = subplot(rows,cols,i); imshow(im{i}, []); title(['Ch. ', num2str(i)]);
            i = 2; sp(i) = subplot(rows,cols,i); imshow(im{i}, []); title(['Ch. ', num2str(i)]);
        end
    
        
    %% fastICA : "Blind source separation"
    
        % all the images should be the same size
        i = 1; imSize = size(im{i});
    
        % pre-process the 2D image data so that is accepted by the FastICA
        % algorithm
        im_toICA = imageToFastICA(im, imSize);    

        % FastICA toolbox/library
        % http://research.ics.aalto.fi/ica/fastica/
        tic;
        % see fastica.m for additional parameters
        [im_fastICA, A, W] = fastica(im_toICA, 'approach', 'defl', 'sampleSize', 1); 
        % [im_fastICA, A, W] = fastica(im_fastICA, 'initGuess', A); % "2nd Pass"
        timeFastICA.fastICAToolbox = toc;
        
            % the rows of "im_fastICA" contain the estimated independent components.
            
            % NOTE! The output of the algorithm is not the same every time
            % you run the algorithm, which is a known problem with ICA. 
            % This could be fixed with bootstrap ICA, e.g.

                % Consistency and asymptotic normality of FastICA and bootstrap FastICA
                % http://dx.doi.org/10.1016/j.sigpro.2011.11.025
                % Nima Reyhani, Jarkko Ylipaavalniemi, Ricardo Vigário, Erkki Oja
                % https://www.researchgate.net/publication/256993961_Consistency_and_asymptotic_normality_of_FastICA_and_bootstrap_FastICA           

        % Arabica : robust ICA in a pipeline
        % https://launchpad.net/arabica-ica   
        n = 100; % n times to run the algorithn with different subset each time
        BS = 0.8;
        tic        
        % [A, W] = api_ica_ica(im_toICA, n) % , 'bootstrap', BS) 
        disp(' '); disp('arabica not working')
        timeFastICA.arabica = toc;

            %   "arabica" uses resampling to
            %   bootstrap the data. If BS is in the range from  0 to 1, that fraction
            %   of samples are used in each run and if BS is greater than 1, that
            %   number of samples are used in each run. Additionally, if the sign of BS
            %   is negative, the order of samples is allowed to change. The value 0
            %   disables bootstrapping. If BS is a function handle, that function is
            %   called to generate the random indices as BS(N) and must return a row
            %   vector of indices in the range from 1 to N.

        % convert back to image
        im_fromICA = ICAtoImage(im_fastICA, imSize);  
        
        % scale the image
        im_fromICA_scaled = scale_IC_components(im, im_fromICA);
                      
        % re-order the ICs to match the input
        [im_fromICA_reOrdered, newOrder] = reOrderICs(im_fromICA_scaled, im);
        
        % merge into RGB
        imIn_RGB = mergeComponentsToRGB(im, rgbOrder);
        imOut_RGB = mergeComponentsToRGB(im_fromICA_reOrdered, rgbOrder); 
        % imOut_RGB_nonscaled = mergeComponentsToRGB(im_fromICA, rgbOrder); 
            
    %% PLOT
    
        fig = figure;
            set(fig,  'Position', [0.01*scrsz(3) 0.325*scrsz(4) 0.4*scrsz(3) 0.60*scrsz(4)])
            plotImageUnmixingOutput(fig, imIn_RGB, imOut_RGB)

        
        
    %% SUBFUNCTIONS
    
        %% ICs do not necessarily come in the same order as input images
        function [im_reOrdered, orderOut] = reOrderICs(im_fromICA, im)
                      
            % convert cell -> mat
            for ch = 1 : length(im_fromICA)
                imIcaMat(:,:,ch) = im_fromICA{ch};
                imMat(:,:,ch) = im{ch};
            end
            
            % try all different permutations
            orderVector = linspace(1, length(im_fromICA), length(im_fromICA));
            allPerms = perms(orderVector);
            difference = zeros(size(allPerms,1), length(orderVector));
            differenceScalar = zeros(size(allPerms,1), 1);
            for perm = 1 : size(allPerms,1)
                tempIca = imIcaMat(:,:,allPerms(perm,:));  
                differenceMatrix = imMat - tempIca; % keep the input same and vary ICs
                difference(perm,:) = sum(sum(abs(differenceMatrix))); % all channels
                differenceScalar(perm) = sum(difference(perm,:)); % sum of channels
            end            

            % the most likely order (I could be wrong, depends on the mixing?)
            % is the one that has the lowest difference
            [lowestSum, permIndex] = min(differenceScalar);
            orderOut = allPerms(permIndex,:);            
            for ch = 1 : length(im_fromICA)
                im_reOrdered{ch} = im_fromICA{orderOut(ch)};
            end
            
            
        %% Normalize ICs and make IC values positive
        function imScaled = scale_IC_components(imIn, im_ICs_Cell)

            noOfICs = length(im_ICs_Cell);
            for ch = 1 : noOfICs              
                imScaled{ch} = abs(im_ICs_Cell{ch});
                imScaled{ch} = imScaled{ch} / max(imScaled{ch}(:));
            end
            % add the intensity scaling from input?
    
            
        %% Plot for the result of unmixing
        function plotImageUnmixingOutput(fig, imIn_RGB, imOut_RGB)
    
            rows = 3; cols = 6;
            
            % merged RGBs
            i = 1;             
                sp(i) = subplot(rows,cols,[1 2 3 7 8 9]);
                imshow(imIn_RGB, []); title('In')
            
            i = 2;             
                sp(i) = subplot(rows,cols,[4 5 6 10 11 12]);
                imshow(imOut_RGB, []); title('Out ICA')
                
            % components
            ind0 = (2 * cols);
            for j = 1 : size(imOut_RGB,3)
                sp(i+j) = subplot(rows,cols,[ind0+j ind0+j+1]);
                    imshow(imOut_RGB(:,:,j), [])
                    ind0 = ind0+1;
                    title(['IC ', num2str(j)])
                    colorbar
            end
            
            
        %% Merge individual channels to RGB
        function imMat = mergeComponentsToRGB(imCell, rgbOrder)
            
            noOfChannels = length(imCell);
            for ch = 1 : noOfChannels
                imMat(:,:,ch) = imCell{rgbOrder(ch)};                
            end
        
            
        %% Each image (2/3D) is converted into a row, 
        % i.e. for 3 channels we have three rows
        function im_toICA = imageToFastICA(im, imSize)

            % isCell = iscell(im)
            numberOfImagesIn = length(im);
            if length(imSize) == 3 % RGB image / hyperspectral / whatever5
                numberOfDataPointsPerImage = imSize(1) * imSize(2) * imSize(3);
            elseif length(imSize) == 2 % Grayscale
                numberOfDataPointsPerImage = imSize(1) * imSize(2);
            else
                error(['your image dimensions? size = ', num2str(imSize)])            
            end

            % images should have the same size
            im_toICA = zeros(numberOfImagesIn, numberOfDataPointsPerImage);
            for i = 1 : numberOfImagesIn            
                reshaped = reshape(im{i},[1,numberOfDataPointsPerImage]);
                im_toICA(i,:) = reshaped;
            end

            
        %% Convert rows back to 2D (grayscale) / 3D (color) matrices
        function im_fromICA = ICAtoImage(im_fastICA, imSize)

            % images should have the same size            
            numberOfImagesIn = size(im_fastICA,1);
            for i = 1 : numberOfImagesIn            
                im_fromICA{i} = reshape(im_fastICA(i,:),imSize);
            end
