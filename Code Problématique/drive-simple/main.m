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

## Load the TORCS simulator functions for drive/control applications
source ../torcs_drive.m

###############################################
# Define helper functions here
###############################################

## usage: GEAR = calculateGear(STATE)
##
## Calculate the gear of the transmission for the current car state.
## Adapted from the code of the WCCI2008 example C++ client: 
## http://cig.ws.dei.polimi.it/wp-content/uploads/2008/04/client-cpp_v02.tgz
##
## Input:
## - STATE, a structure describing the current state of the car (see function 'waitForState').
##
## Output:
## - GEAR, the selected gear. -1 is reverse, 0 is neutral and the forward gear can range from 1 to 6.
##
function gear = calculateGear(state)
  
  ## Gear Changing Constants
  GEAR_UP=[5000,6000,6000,6500,7000,0];
  GEAR_DOWN=[0,2500,3000,3000,3500,3500];

  ## If gear is 0 (N) or -1 (R) just return 1 
  if (state.gear<1)
    gear = 1;
  ## Check if the RPM value of car is greater than the one suggested 
  ## to shift up the gear from the current one.   
  elseif (state.gear < 6 && state.rpm >= GEAR_UP(state.gear))
    gear = state.gear + 1;
    return;
  else
    ## Check if the RPM value of car is lower than the one suggested 
    ## to shift down the gear from the current one.
    if (state.gear > 1 && state.rpm <= GEAR_DOWN(state.gear))
      gear = state.gear - 1;
    else 
      ## Otherwise keep current gear
      gear = state.gear;
    endif
  endif
endfunction

## usage: STEERING = calculateSteering(STATE)
##
## Calculate the steering value for the current car state.
## Adapted from the code of the WCCI2008 example C++ client: 
## http://cig.ws.dei.polimi.it/wp-content/uploads/2008/04/client-cpp_v02.tgz
##
## Input:
## - STATE, a structure describing the current state of the car (see function 'waitForState').
##
## Output:
## - STEERING, the steering value. -1 and +1 means respectively full left and right, that corresponds to an angle of 0.785398 rad.
##
function steering = calculateSteering(state)
  ## Steering constants
  steerLock=0.785398;
  steerSensitivityOffset=80.0;
  wheelSensitivityCoeff=1;

  ## Steering angle is computed by correcting the actual car angle w.r.t. to track 
	## axis and to adjust car position w.r.t to middle of track
  targetAngle=(state.angle-state.trackPos*0.5);
  ## At high speed, reduce the steering command to avoid loosing control
  if (state.speedX > steerSensitivityOffset)
      steering = targetAngle/(steerLock*(state.speedX-steerSensitivityOffset)*wheelSensitivityCoeff);
  else
      steering = (targetAngle)/steerLock;
  endif
  
  ## Normalize steering
  if (steering < -1)
      steering = -1;
  elseif (steering > 1)
      steering = 1;
  endif
endfunction

## usage: ACCELERATION = calculateAcceleration(STATE)
##
## Calculate the accelerator (gas pedal) value for the current car state.
## Adapted from the code of the WCCI2008 example C++ client: 
## http://cig.ws.dei.polimi.it/wp-content/uploads/2008/04/client-cpp_v02.tgz
##
## Input:
## - STATE, a structure describing the current state of the car (see function 'waitForState').
##
## Output:
## - ACCELERATION, the virtual gas pedal (0 means no gas, 1 full gas), in the range [0,1].
##
function accel = calculateAcceleration(state)
    ## Accel and Brake Constants
    maxSpeedDist=50.0;
    maxSpeed=150.0;
    sin10 = 0.17365;
    cos10 = 0.98481;

    ## Checks if car is out of track
    if (state.trackPos < 1 && state.trackPos > -1)
        ## Reading of sensor at +10 degree w.r.t. car axis
        rxSensor=state.track(9);
        ## Reading of sensor parallel to car axis
        cSensor=state.track(10);
        ## Reading of sensor at -10 degree w.r.t. car axis
        sxSensor=state.track(11);

        ## Track is straight and enough far from a turn so goes to max speed
        if (cSensor>maxSpeedDist || (cSensor>=rxSensor && cSensor >= sxSensor))
            targetSpeed = maxSpeed;
        else
            ## Approaching a turn on right
            if(rxSensor>sxSensor)
                ## Computing approximately the "angle" of turn
                h = cSensor*sin10;
                b = rxSensor - cSensor*cos10;
                sinAngle = b*b/(h*h+b*b);
                ## Estimate the target speed depending on turn and on how close it is
                targetSpeed = maxSpeed*(cSensor*sinAngle/maxSpeedDist);
            ## Approaching a turn on left
            else
                ## Computing approximately the "angle" of turn
                h = cSensor*sin10;
                b = sxSensor - cSensor*cos10;
                sinAngle = b*b/(h*h+b*b);
                ## Estimate the target speed depending on turn and on how close it is
                targetSpeed = maxSpeed*(cSensor*sinAngle/maxSpeedDist);
            endif
        endif

        ## Accel/brake command is expontially scaled w.r.t. the difference between target speed and current one
        accel = 2.0/(1.0+exp(state.speedX - targetSpeed)) - 1.0;
    else
        ## When out of track, return a moderate acceleration command
        accel = 0.3;
    endif
endfunction

## usage: ACTION = drive(STATE)
##
## Calculate the accelerator, brake, gear and steering values based on the current car state.
##
## Input:
## - STATE, a structure describing the current state of the car (see function 'waitForState').
##
## Output:
## - ACTION, the structure describing the action to execute (see function 'applyAction').
##
function action = drive(state)
  action.accel=calculateAcceleration(state);
  action.brake=1.0 - action.accel;
  action.gear=calculateGear(state);
  action.steer=calculateSteering(state);
endfunction

###############################################
# Define code logic here
###############################################

## NOTE: the unwind_protect block is necessary to shutdown the simulator
##       if any error occurs in the code. DO NOT REMOVE IT!
unwind_protect

  ## Connect to simulation server.
  ## NOTE: This function is defined in the file torcs_drive.m
  startSimulator(mode='gui');

  ## Loop indefinitely, or until:
  ## - The maximum number of laps is reached in the simulation.
  ## - Simulator is shutdown using the menu (press ESC during the simulation).
  ## - Octave is terminated by CTRL-C on the Command Window.
	counter = 1;
	while 1
    
    ## Grab the car state from the simulator.
    ## NOTE: This function is defined in the file torcs_drive.m
		[state, status] = waitForState();
		if strcmp(status,"running") == 0
			## Simulator is shutting down or no longer running, so exit.
			break;
		endif
	
    ## Calculate the optimal action for the current car state.
		action = drive(state);
		
    ## Send an action to be executed by the simulator.
    ## NOTE: This function is defined in the file torcs_drive.m
    applyAction(action);
		
		## Record the current state and action in the internal saving buffer.
    ## NOTE: This function is defined in the file torcs_drive.m
		doRecord(state, action)
    
    ## Perform a saving operation every 100 recorded states.
		if mod(counter,100) == 0
			disp(sprintf("Saved %d states: distance raced = %1.1f km", counter, state.distRaced/1000.0));
      ## Save all recorded data accumulated so far.
      ## NOTE: This function is defined in the file torcs_drive.m
			saveRecordedData('data/recorded.mat');
		endif
		counter = counter + 1;
	endwhile
	
  ## Save all recorded data accumulated during the simulation to disk.
  ## NOTE: This function is defined in the file torcs_drive.m
	saveRecordedData('data/recorded.mat');
  
unwind_protect_cleanup
  ## NOTE: this block of code is called on exit
	## Close the simulator
	stopSimulator();
  disp('All done.');
end_unwind_protect

