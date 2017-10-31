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
global client verbose recordedData recordedDataCounter simPid

client = socket(AF_INET, SOCK_DGRAM, 0);
recordedData = struct();
recordedDataCounter = 0;
verbose = 0;
simPid = -1;

###############################################
# Defined functions
###############################################

## usage: reinitSimulator()
##
## Reset the global variables used by the simulator
##
function reinitSimulator()
  global client verbose recordedData recordedDataCounter simPid

  client = socket(AF_INET, SOCK_DGRAM, 0);
  recordedData = struct();
  recordedDataCounter = 0;
  simPid = -1;
endfunction

## usage: startSimulator(MODE, CONFIG)
##
## Start the TORCS simulator. 
##
## Input:
## - MODE, set to 'gui' to enable 3D graphic display (a window will appear),
##   or to 'nogui' (default) for console mode. The console mode is significantly faster
##   since no rendering is required.
## - CONFIG,  to the path of the XML configuration file for the race.
##   If no file path is provided, the default file './config/race-config-nogui.xml' is used.
##   The standard output of the TORCS simulation subprocess will be printed on console.
##
## Example:
##
## startSimulator()
function startSimulator(mode='gui', config='default')
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
        disp('Sending identifier to server...')
        id_msg = 'wcci2008';
        rc = send(client,id_msg);
        if ( rc ~= length(id_msg) )
          error('Identifier failed to be sent to server.');
          break;
        end
        fflush(stdout);
        
        ## Read message from server
        try
           RECV_TIMEOUT = 2.0;
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
        if strcmp(msg,"***identified***")
          disp('Client identification successfull.')
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
		if strcmp(mode,"gui")
      ## 3D graphic display enabled
      disp('Launching simulator (gui enabled)...');
      if strcmp(config,"default")
        ## If no configuration is provided, expect a file in a config sub-directory (relative path)
        [err, msg] = exec('torcs', sprintf('-s -d -nofuel -nodamage -nolaptime -r %s/config/race-config-gui.xml', pwd()));
      else
        ## Configuration file provided with an absolute path
        [err, msg] = exec('torcs', sprintf('-s -d -nofuel -nodamage -nolaptime -r %s', config));
      endif
		   
		elseif strcmp(mode,"nogui")
      ## 3D graphic display disabled
      disp('Launching simulator (gui disabled)...');
      if strcmp(config,"default")
        ## If no configuration is provided, expect a file in a config sub-directory (relative path)
        [err, msg] = exec('torcs', sprintf('-d -nogui -nofuel -nodamage -nolaptime -r %s/config/race-config-nogui.xml', pwd()));
      else
        ## Configuration file provided with an absolute path
        [err, msg] = exec('torcs', sprintf('-d -nogui -nofuel -nodamage -nolaptime -r %s', config));
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

## usage: [STATE, STATUS] = waitForState(BLOCKING)
##
## Evaluate a set of parameters in the TORCS simulator.
##
## Input:
## - BLOCKING, set to 1 to enable blocking mode, 0 otherwise. In blocking mode, the simulator
##   will wait for an action to be received before calculating the next simulation step. This is
##   the proper behaviour for control application. In non-blocking mode, the simulator send the states
##   without expecting any action in return. This is the proper behaviour for recording states.
##   The default value is to blocking mode (1).
##
## Output:
## - STATE, a structure with the following fields:
##     Adapted from the Software Manual of the Car Racing Competition @ WCCI2008
##     http://julian.togelius.com/Loiacono2008The.pdf
##
##      angle, the angle between the car direction and the direction of the track axis. Range of [-pi,pi]. [rad]
##      curLapTime, the time elapsed during current lap. [seconds]
##      damage, the current damage of the car (the higher is the value the higher is the damage). [points]
##      distFromStart, the distance of the car from the start line along the track line. [meters]
##      distRaced, the distance covered by the car from the beginning of the race. [meters]
##      fuel, the current fuel level. [liters]
##      gear, the current gear. -1 is reverse, 0 is neutral and the forward gear can range from 1 to 6.
##      lastLapTime, the time to complete the last lap. [seconds]
##      opponents, a vector of 18 sensors that detects the opponent distance (range is [0,100]) 
##                 within a specific 10 degrees sector: each sensor covers 10 degrees, from -pi/2 to +pi/2 
##                 in front of the car. [meters]
##      racePos, the position in the race with to respect to other cars.
##      rpm, the number of rotation per minute of the car engine in the range [2000, 7000]. [rpm]
##      speedX, the speed of the car along the longitudinal axis of the car. [km/h]
##      speedY, the speed of the car along the transverse axis of the car. [km/h]
##      track, a vector of 19 range finder sensors: each sensors represents the distance between the track 
##             edge and the car. Sensors are oriented every 10 degrees from -pi/2 and +pi/2 in front of the car.
##             Distance are in meters within a range of 100 meters. When the car is outside of the 
##             track (i.e., pos is less than -1 or greater than 1), these values are not reliable! [meters]
##      trackPos, the distance between the car and the track axis. The value is normalized w.r.t to the track 
##             width: it is 0 when car is on the axis, -1 when the car is on the right edge of the track and +1
##             when it is on the left edge of the car. Values greater than 1 or smaller than -1 means that the 
##             car is outside of the track.
##      wheelSpinVel, a vector of 4 sensors representing the rotation speed of wheels. [rad/s]
##
## - STATUS, the current status of the simulator. Set to 'running' if the simulator is still
##   running and available for parameters evaluation, 'restart' if the simulator was requested to restart,
##   or 'shutdown' if the simulator is down. If that last case, one should probably restart the simulator or exit.
##
## Example:
##
## [state, status] = waitForState()
function [state, status] = waitForState(blocking=1)
	global client verbose

  ## Initial empty structure
  state = struct();
  
	if verbose
	  disp('Waiting for car state data...')
	endif
	
    ## Read state data from server
    recvSuccess = 0;
    while !recvSuccess
      ## Read message from server
      try
        RECV_TIMEOUT = 2.0;
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
        msg = '';
      end_try_catch
    endwhile

  ## Parse message
	if strcmp(msg,"***shutdown***")
		disp('Client shutdown from server.')
		shutdownClient=1;
		status = 'shutdown';
	elseif strcmp(msg,"***restart***")
		disp('Client restart from server.')
		status = 'restart';
	elseif msg
		## Parse state data from message
		if verbose
		  disp(msg)
		endif
		state = str2state(msg);
		status = 'running';

		## Send an acknowledge message to simulator if in non-blocking mode
		if ~blocking
      msg = "ACK";
      rc = send(client, msg);
      if ( rc ~= length(msg) )
        error('Acknowledge failed to be sent to server.');
      end
		endif
	endif

  if verbose
    fflush(stdout);
    fflush(stderr);
	endif
endfunction

## usage: applyAction(ACTION)
##
## Send an action to the executed by the TORCS simulator.
## Call this function only after receiving the car state in blocking mode.
##
## Input:
## - ACTION, a structure with the following fields:
##     Adapted from the Software Manual of the Car Racing Competition @ WCCI2008
##     http://julian.togelius.com/Loiacono2008The.pdf
##
##     accel, the virtual gas pedal (0 means no gas, 1 full gas), in the range [0,1].
##     brake, the virtual brake pedal (0 means no brake, 1 full brake), in the range [0,1].
##     gear, the gear value. -1 is reverse, 0 is neutral and the forward gear can range from 1 to 6.
##     steer, the steering value. -1 and +1 means respectively full left and right, that corresponds to an angle of 0.785398 rad.
##
## Example:
##
## action.accel=1.0;
## action.brake=0.0;
## action.gear=1;
## action.steer=0;
## applyAction(action)
function applyAction(action)
	global client verbose

	## Send action to server
	msg = action2str(action, 0);
	if verbose
	  disp('Sending action to server...');
	  disp(msg)
	endif
	rc = send(client, msg);
	if ( rc ~= length(msg) )
	  error('Action failed to be sent to server.');
	end
endfunction

## usage: doRecord(STATE, ACTION)
##
## Record a car state and associated action to an internal buffer.
##
## Input:
## - STATE, a structure describing the car state (see function 'waitForState').
## - ACTION, a optional structure describing the action to execute (see function 'applyAction').
##
function doRecord(state, action=struct())
	global recordedData recordedDataCounter

  recordedDataCounter = recordedDataCounter +1;
  
	## Append action variables to state
	var_names = fieldnames(action);
	for i=1:length(var_names)
    ## Rename action variables to with 'Cmd' suffix to avoid conflicts.
		name = var_names{i};
		state.([name, 'Cmd']) = action.(name);
	endfor

  DYNAMIC_ARRAY_BLOCK_SIZE = 2048;
  if recordedDataCounter == 0
    ## Initialize field
    recordedData(1:DYNAMIC_ARRAY_BLOCK_SIZE) = state;
  elseif recordedDataCounter > length(recordedData)
		## Allocate more memory
		recordedData(recordedDataCounter:recordedDataCounter+DYNAMIC_ARRAY_BLOCK_SIZE) = state;
  endif 
  
  ## Append state value to buffer
	recordedData(recordedDataCounter) = state;

endfunction

## usage: DATA = getRecordedData()
##
## Get a copy of the recorded state and associated action data from the internal buffer.
##
## Output:
## - DATA, a structure array describing the recorded car states (see function 'waitForState').
##    
function data = getRecordedData()
	global recordedData recordedDataCounter
 
  data = recordedData(1:recordedDataCounter);
endfunction

## usage: saveRecordedData(FILEPATH)
##
## Save a copy of the recorded state and associated action data from the internal buffer to disk.
## Data is saved in a MATLAB-compatible binary format.
##
## Input:
## - FILEPATH, the output.
##   
function saveRecordedData(filepath)

	data = getRecordedData();

  ## Create directory if it does not exits
	[outputDir, fileName] = fileparts(filepath);
	if (exist(outputDir) ~= 7)
	    mkdir(outputDir);
	end
	save("-mat-binary", filepath, "data");
endfunction

###############################################
# Defined helper functions
###############################################

## usage: STATE = str2state(MSG)
##
## Parse a state message from string and convert it to a structure.
##
## Input:
## - MSG, the state message string to parse. The input format is as follow:
##        (angle -0.00396528)(curLapTime -0.962)(damage 0)(distFromStart 5759.1)(distRaced 0)(fuel 80)(gear 0)
##
## Output:
## - STATE, the state structure with defined variables and values.
##  
function state = str2state(msg)
  elems = strsplit(msg,'(');
  for i=2:size(elems,2)
    [var_name,var_values] = strtok(elems{i});
    state.(var_name) = sscanf(var_values(1:end-1),'%f');
  endfor
endfunction

## usage: MSG = action2str(ACTION, META)
##
## Convert an action structure to a string message representation. 
##
## Input:
## - ACTION, the action structure.
## - META, the meta-variable controlling the restart of the simulation. Set to 1 to restart the simulation, otherwise 0.
##   
## Output:
## - MSG, the string message representation. The output format is as follow:
##        (accel 0.1)(brake 0.962)(steer 0.2322)(gear 2)(meta 0)
##  
function msg = action2str(action, meta)
  msg = '';
  var_names = fieldnames(action);
  for i=1:length(var_names)
    msg = [msg, sprintf('(%s %f)', var_names{i}, action.(var_names{i}))];
  endfor
  msg = [msg, sprintf('(meta %d)', meta)];
endfunction
