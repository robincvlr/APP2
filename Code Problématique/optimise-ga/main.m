%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% Copyright (c) 2014, Simon Brodeur
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without modification,
% are permitted provided that the following conditions are met:
% 
%  - Redistributions of source code must retain the above copyright notice, 
%    this list of conditions and the following disclaimer.
%  - Redistributions in binary form must reproduce the above copyright notice, 
%    this list of conditions and the following disclaimer in the documentation 
%    and/or other materials provided with the distribution.
%  - Neither the name of Simon Brodeur nor the names of its contributors 
%    may be used to endorse or promote products derived from this software 
%    without specific prior written permission.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
% ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
% WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
% IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
% INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT 
% NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
% OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
% WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
% POSSIBILITY OF SUCH DAMAGE.
%

source ../torcs_opt.m

###############################################
# Define code logic here
###############################################

% Connect to simulation server
startSimulator(mode='nogui');

unwind_protect
	
  # Loop a few times for demonstration purpose
  for i=1:30

    # Generate a random vector of parameters in the proper interval
    # (see NB_PARAMS, MAX_PARAM_VALUES and MIN_PARAM_VALUES constants)
    disp(sprintf('Generating new parameter vector (no.%d)', i));
    
    % Uncomment to generate random values in the proper range for each variable
    %cvalues = (MAX_PARAM_VALUES - MIN_PARAM_VALUES) .* rand(1, NB_PARAMS) + MIN_PARAM_VALUES;
    
    % Uncomment to use the default values in the TORCS simulator
    cvalues = [2.5, 1.5, 1.5, 1.5, 1.0, 4.5, 14.0, 6.0];
    
    disp(cvalues);
      
    % Perform the evaluation with the simulator
    [result, status] = evaluateParameters(cvalues, maxEvaluationTime=1000);
      
    % Display data
    disp('##################################################');
    disp('Results:');
    disp(sprintf('Top speed (km/h)   =   %f', result.topspeed));
    disp(sprintf('Distance raced (m) =   %f', result.distraced));
    disp(sprintf('Fuel used (l)      =   %f', result.fuelUsed));
    disp('##################################################');	
  endfor
  
  stopSimulator();
  
unwind_protect_cleanup
	% Close the simulator
	stopSimulator();
  disp('All done.');
end_unwind_protect
