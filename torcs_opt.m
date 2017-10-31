## Copyright (c) 2014, Simon Brodeur
## All rights reserved.
## 
## Redistribution and use in source and binary forms, with or without modification,
## are permitted provided that the following conditions are met:
## 
##  - Redistributions of source code must retain the above copyright notice, 
##    this list of conditions and the following disclaimer.
##  - Redistributions in binary form must reproduce the above copyright notice, 
##    this list of conditions and the following disclaimer in the documentation 
##    and/or other materials provided with the distribution.
##  - Neither the name of Simon Brodeur nor the names of its contributors 
##    may be used to endorse or promote products derived from this software 
##    without specific prior written permission.
## 
## THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
## ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
## WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
## IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
## INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT 
## NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
## OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
## WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
## ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
## POSSIBILITY OF SUCH DAMAGE.
##

## Author: Simon Brodeur <simon.brodeur@usherbrooke.ca>

## Load the socket toolbox
pkg load sockets;

## Avoid the console blocking
more off;

###############################################
# Defined global variables
###############################################

## !!! WARNING: FOR INTERNAL USE ONLY. DO NOT MODIFY THESE VARIABLES !!!
global client verbose simPid

client = socket(AF_INET, SOCK_DGRAM, 0);
verbose = 0;
simPid = -1;

## Constants
global NB_PARAMS MIN_PARAM_VALUES MAX_PARAM_VALUES
NB_PARAMS = 8;
MIN_PARAM_VALUES = [0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0];
MAX_PARAM_VALUES = [5.0, 5.0, 5.0, 5.0, 5.0, 10.0, 90.0, 90.0];

###############################################
# Defined functions
###############################################

## usage: reinitSimulator()
##
## Reset the global variables used by the simulator
##
function reinitSimulator()
  global client simPid

  client = socket(AF_INET, SOCK_DGRAM, 0);
  simPid = -1;
endfunction

## usage: startSimulator(MODE, CONFIG)
##
## Start the TORCS simulator. 
##
## Input:
## - MODE, set to 'gui' to enable 3D graphic display (not yet supported),
##   or to 'nogui' (default) for console mode. The console mode is significantly faster
##   since no rendering is required.
## - CONFIG,  to the path of the XML configuration file for the race.
##   If no file path is provided, the default file './config/race-config-nogui.xml' is used.
##   The standard output of the TORCS simulation subprocess will be printed on console.
##
## Example:
##
## startSimulator()
function startSimulator(mode='nogui', config='default')
	global client verbose simPid

	## Start server in a subprocess
	[pid, msg] = fork();
  
  ## Parent process
	if pid > 0 
    simPid = pid;
  
	  try
      ## Open an UDP socket for communication with server
      server_info = struct("addr", "localhost", "port", 3001);
      rc = connect(client, server_info);
      if ( rc ~= 0 )
        error('Could not connect to server.');
      endif
      disp('Socket connected to server.')	
      fflush(stdout);

      ## Loop while no connection has been established
      connected=0;
      do
        ## Connect and send the identifier
        disp('Requesting information from server...')
        id_msg = 'info?';
        rc = send(client,id_msg);
        if ( rc ~= length(id_msg) )
          error('Request failed to be sent to server.');
          break;
        end
        fflush(stdout);

        ## Read message from server
        try
           RECV_TIMEOUT = 5.0;
          [buf, len_buf] = recv(client,10000,0,RECV_TIMEOUT);
          if ( buf == -1 || len_buf ~= length(buf) )
            error('State failed to be received from server.');
          endif
          msg = char(buf)(1:end-1);
        catch
          if !checkSimulator()
             error('Simulator closed unexpectedly');
          endif
          msg = '';
        end_try_catch
        
        ## Parse message
        elems = strsplit(msg, ' ');
        if length(elems) > 2 && strcmp(elems{1},"info")
          global NB_PARAMS
          NB_PARAMS = str2double(elems{2});
          disp('Client identification successfull.')
          disp(sprintf('Number of parameters: %d', NB_PARAMS));
          fflush(stdout);
          connected=1;
        else
          disp('Waiting for simulator to initialize.')
          fflush(stdout);
          sleep(2);
        endif
      until connected
	  catch
      ## Disconnect on error
      disp('Client shutdown.')
      fflush(stdout);
      disconnect(client);
      
      stopSimulator();

      rethrow(lasterror);
	  end_try_catch

	## Child process
	elseif pid == 0 

    ## Select the proper simulation mode
		if strcmp(mode,"nogui")
      disp('Launching simulator (gui disabled)...');
      if strcmp(config,"default")
        ## If no configuration is provided, expect a file in a config sub-directory (relative path)
        [err, msg] = exec('torcs', sprintf('-nogui -nofuel -nodamage -nolaptime -r %s/config/race-config-nogui.xml', pwd()));
      else
        ## Configuration file provided with an absolute path
        [err, msg] = exec('torcs', sprintf('-nogui -nofuel -nodamage -nolaptime -r %s', config));
      endif
		else
		  disp(sprintf("Unsupported simulation mode: %s", mode));
		endif

		disp('Simulator terminated.');
		exit();
	else	
		error(sprintf('Unable to start server: %s', msg));
	endif
endfunction

## usage: RUNNING = checkSimulator()
##
## Check if the TORCS simulator is running. 
##
## Output:
## - RUNNING, 1 if the simulator subprocess is still running, 0 otherwise.
##
## Example:
##
## running = checkSimulator()
function running = checkSimulator()
   global simPid
  [pid, status, msg] = waitpid (simPid, WNOHANG | WUNTRACED);
  running = pid >= 0;
endfunction

## usage: stopSimulator()
##
## Stop the TORCS simulator if it is running. This will kill the
## the simulator subprocess.
##
## Example:
##
## stopSimulator()
function stopSimulator()
    global simPid
    
    if simPid > 0 && checkSimulator()
      disp(sprintf('Killing simulator subprocess (pid = %d)...', simPid));
      ## Just in case something went wrong with the simulator,
      ## perform a manual kill
      [err, msg] = kill(simPid,SIG().KILL);
      if err || checkSimulator()
        ## No more chance
        system('killall torcs-bin');
      endif
     endif
endfunction

## usage: [RESULT, STATUS] = evaluateParameters(VALUES, MAX_EVALUATION_TIME)
##
## Evaluate a set of parameters in the TORCS simulator.
##
## Input:
## - VALUES, the 1-dimensional vector of size (1,5) to evaluate.
## - MAX_EVALUATION_TIME, the maximum time ticks (40 ms step) allowed for the simulation.
##   The default value is set to 1000 (i.e. 40 sec of simulation time).
##
## Output:
## - RESULT, a structure with the following fields:
##      bestlap, the time of the best lap so far (0 if no lap was completed). [seconds]
##      topspeed, the top speed of the car in. [km/h]
##      distraced, the total distance travelled by the car. [meters]
##      damage, the accumulated damage points (0 if no collision occured). [points]
##      fuelUsed, the volume of fuel used to power to car engine. [liters]
## - STATUS, the current status of the simulator. Set to 'running' if the simulator is still
##   running and available for parameters evaluation, otherwise 'shutdown' if the simulator is down.
##   If that last case, one should probably restart the simulator or exit.
##
## Example:
##
## [result, status] = evaluateParameters([0.5, 0.1, 0.75, 0.15, 0.25], maxEvaluationTime=1000)
function [result, status] = evaluateParameters(values, maxEvaluationTime=1000)
	global client verbose
	global NB_PARAMS MIN_PARAM_VALUES MAX_PARAM_VALUES
  
  ## Make sure the number of parameters is right
	if length(values) ~= NB_PARAMS
	   error(sprintf('Wrong number of parameters provided by optimisation algorithm: expected %d, received %d', NB_PARAMS, length(values)));
	end

  ## Rescale values to interval [0,1]
  values = (values - MIN_PARAM_VALUES) ./ (MAX_PARAM_VALUES - MIN_PARAM_VALUES);
  if max(values) > 1.0 || min(values) < 0.0
      error('Not all parameters are in the proper range!')  
  endif
  
	## Send evaluation parameters to optimisation server
	msg = ['eval ', int2str(maxEvaluationTime)];
	for i=1:NB_PARAMS
	   msg = [msg, ' ', sprintf('%f',values(i))];
	endfor
	if verbose
	  disp('Sending evaluation parameters to optimisation server...');
	  disp(msg);
	endif
	rc = send(client, msg);
	if ( rc ~= length(msg) )
	  error('Evaluation parameters failed to be sent to server.');
	end
	
  ## Loop until result is received from the simulator
  recvSuccess = 0;
  while !recvSuccess
    ## Read message from server
    try
       RECV_TIMEOUT=5.0;
      [buf, len_buf] = recv(client,10000,0,RECV_TIMEOUT);
      if ( buf == -1 || len_buf ~= length(buf) )
        error('State failed to be received from server.');
      endif
      msg = char(buf)(1:end-1);
      recvSuccess = 1;
    catch
      if !checkSimulator()
         disp('Simulator closed unexpectedly');
         status = 'shutdown';
         break;
      endif
    end_try_catch
  endwhile
  
  if verbose
	  disp('Optimisation results...');
    disp(msg);
	endif
  
  ## Parse message
	elems = strsplit(msg, ' ');
	if length(elems) == 6 && strcmp(elems{1},"result")
	  result = struct();
	  result.bestlap = str2double(elems{2});
	  result.topspeed = str2double(elems{3});
	  result.distraced = str2double(elems{4});
	  result.damage = str2double(elems{5});
	  result.fuelUsed = str2double(elems{6});
    
    if isnan(result.fuelUsed) || result.fuelUsed < 0
        error('Fuel used should be greater than zero!');
    endif
    
    if result.damage > 0
        error('No damage should have occured during simulation!');
    endif
    
	  status = 'running';
	elseif length(elems) == 1 && strcmp(elems{1},"time-over")
	  ## NOTE: should not happen since timeout value was set high on server
	  error('Time-over response received from server');
	else
	  error(['Unable to parse result: ', msg]);
	endif
  
  if verbose
    fflush(stdout);
    fflush(stderr);
	endif
endfunction

###############################################
# Defined helper functions
###############################################

## None
