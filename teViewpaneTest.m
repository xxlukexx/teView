classdef teViewpaneTest < teViewpane
    
    properties
        CheckerSize = 100;
    end
    
    methods
        
        function Draw(obj)
            cols = [    000, 000, 000   ;...
                        255, 255, 255   ];
            nx = ceil(obj.Width / obj.CheckerSize);
            ny = ceil(obj.Height / obj.CheckerSize);
            colCounter = 1;
            for row = 1:ny
                for col = 1:nx
                    x1 = obj.CheckerSize * (col - 1);
                    y1 = obj.CheckerSize * (row - 1);
                    x2 = obj.CheckerSize * col;
                    y2 = obj.CheckerSize * row;
                    s.function = 'FillRect';
                    s.args = {...
                        cols(1 + mod(colCounter, 2), :),...
                        [x1, y1, x2, y2],...
                        };
                    obj.DrawBuffer.AddItem(s)
                    colCounter = colCounter + 1;
                end
            end 
        end
        
    end
    
end