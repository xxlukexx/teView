classdef vpaAOI < teViewpane
    
    properties
        Name = 'UnnamedAOI';
        InterpolateResultsSecs = 0
        TriggerToleranceSecs = 0
    end
    
    properties (Dependent, SetAccess = private)
        SubjectTable
        LookVector
    end
    
    properties (Abstract, SetAccess = protected, SetObservable)
        In
    end
    
    properties (SetAccess = protected)
        PostInterpMissing
        PostInterpX
        PostInterpY
    end
    
    properties (Access = protected)
        prID 
        prPropVal
        prLookVector
    end
    
    methods 
               
        function Clear(~)
            return
        end
        
        function [in, piMissing, piX, piY] = PostProcessScores(obj, gaze, in) 
        % post-processing of AOI results. 
        
            % if the second arg is an 'in' vector of AOI scores,
            % post-process this. Otherwise use the .In property of the
            % class
            if ~exist('in', 'var') || isempty(in)
                in = obj.In;
                storeResultsInClass = true;
            else
                storeResultsInClass = false;
            end
            
            % currently we prefer to be passed 'gaze' as a teGazeData
            % instance. Previously this argument was a vpaEyeTracking
            % object (which contained a teGazeData property). For back
            % compat we still support this
            if isa('gaze', 'vpaEyeTrackingData')
                gaze = gaze.gaze;
            end
        
            % determine whether we need to prepare the data for
            % post-processing
            doPost = obj.InterpolateResultsSecs > 0 ||...
                obj.TriggerToleranceSecs > 0;
            if ~doPost, return, end
            
        % interpolate 
        
            if obj.InterpolateResultsSecs > 0
                [in, piMissing, piX, piY] = etInterpolateAOI(in, gaze,...
                    obj.InterpolateResultsSecs);                
            end
            
        % trigger tolerance
        
            if obj.TriggerToleranceSecs > 0
                in = etAOITriggerTolerance(in,...
                    gaze, obj.TriggerToleranceSecs);
            end 
            
            if storeResultsInClass
                obj.In = in;
                obj.PostInterpMissing = piMissing;
                obj.PostInterpX = piX;
                obj.PostInterpY = piY;
                obj.calculateLookVector
            end
            
%             in_disp = (obj.In * 3) - in_int - in_trig;
%             heatmap(double(in_disp(:, :, 1)), 'GridVisible', 'off', 'Colormap', jet);
%             
%             subplot(1, 3, 1)
%             heatmap(double(obj.In(:, :, 1)), 'GridVisible', 'off');
%             title('Original')
%             subplot(1, 3, 2)
%             heatmap(double(in_int(:, :, 1)), 'GridVisible', 'off');
%             title('Interpolated')
%             subplot(1, 3, 3)
%             heatmap(double(in_trig(:, :, 1)), 'GridVisible', 'off');
%             title('Trigger Tolerance')
            
        end
        
        % get/set 
        function val = get.SubjectTable(obj)
        % returns a SubjectTable. This is a table with a row for each 
        % subject, and a column for the mean proportion looking time for
        % each AOI
            
            if isempty(obj.In)
                val = [];
            end
            
            val = table;
            val.ID = obj.prID;
            
            % collapse across time
            totalSamps = sum(~isnan(obj.In), 1);
            totalIn = nansum(obj.In, 1);
            propIn = shiftdim(totalIn ./ totalSamps, 1);
            
            % make table of AOI scores and concat to table with IDs
            tabScores =  array2table(propIn, 'VariableNames',...
                obj.AOIDefinition(:, 1));
            tabPropVal = array2table(obj.prPropVal', 'VariableNames',...
                {'prop_valid'});
            val = [val, tabScores, tabPropVal];
            
        end
        
        function val = get.LookVector(obj)
            val = obj.prLookVector;
        end
        
        % utlities
        function AssertValidEyeTrackingData(~, et)
            
            % check that a valid instance of vpaEyeTrackingData has been
            % passed
            if ~exist('et', 'var') || ~isa(et, 'vpaEyeTrackingData') ||...
                    ~et.Valid
                error('Missing or invalid eye tracking data passed.')
            end
            
        end
        
    end
    
    methods (Hidden)
        
        function calculateLookVector(obj)
        % the LookVector property (dependent upon prLookVector) is all AOI
        % scores averaged across subject. So the mean AOI score per sample.
        % It's size is [numAOIs, numSamps]. If we have only one AOI then we
        % simply average the scores and place into the second dim on the
        % LookVector. If more than one AOI, we use shiftdim to reshape the
        % matrix correctly. 
        
            numAOIs = size(obj.In, 3);
            obj.prLookVector = [];
            switch numAOIs
                case 1
                    obj.prLookVector(1, :) = nanmean(obj.In, 2);
                otherwise
                    obj.prLookVector = shiftdim(nanmean(obj.In, 2), 2);
            end
            
        end
        
    end
    
end