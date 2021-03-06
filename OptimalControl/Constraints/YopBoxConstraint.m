% Copyright 2019, Viktor Leek
%
% This file is part of Yop.
%
% Yop is free software: you can redistribute it and/or modify it
% under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, either version 3 of the License, or any
% later version.
% Yop is distributed in the hope that it will be useful, but
% WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
% Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with Yop.  If not, see <https://www.gnu.org/licenses/>.
% -------------------------------------------------------------------------
classdef YopBoxConstraint < YopConstraint

    methods
        function obj = YopBoxConstraint(constraint)
            
            [isMember, memberNumber] = YopBoxConstraint.isMember(constraint);
            assert(isMember);
            
            pattern = YopBoxConstraint.getMemberPattern(memberNumber);
            
            [variable, upper, lower] = pattern.parse(constraint);
            
            obj@YopConstraint(constraint, variable, upper, lower);
            
        end        
    end
    
    methods (Static)       
        
        function patterns = memberPatterns()
            
            p1 = YopConstraintPattern({'numeric' '<=' 'x' '<=' 'numeric'}, ...
                @(c) c{3}, @(c) c{5},@(c) c{1});            
            
            p2 = YopConstraintPattern({'numeric' '==' 'x'}, ...
                @(c) c{3}, @(c) c{1}, @(c) c{1});            
            
            p3 = YopConstraintPattern({'numeric' '<=' 'x'}, ...
                @(c) c{3}, @(c) inf(size(c{3})),  @(c) c{1});
                        
            p4 = YopConstraintPattern({'numeric' '>=' 'x'}, ...
                @(c) c{3}, @(c) c{1}, @(c) -inf(size(c{3})));            
            
            patterns = [p1, p2, p3, p4];
            
        end
        
        function pattern = getMemberPattern(patternNumber)
            patterns = YopBoxConstraint.memberPatterns;
            pattern = patterns(patternNumber);
        end
        
        function [value, memberNumber] = isMember(constraint)
            patterns = YopBoxConstraint.memberPatterns();
            patternMatch = zeros(size(patterns));
            memberNumber = [];
            for k=1:length(patterns)
                if patterns(k).match(constraint)
                    memberNumber = k;
                    patternMatch(k) = 1;
                end
            end
            
            assert(sum(patternMatch)<=1);
            value = ~isempty(memberNumber);            
        end               
    end
end























