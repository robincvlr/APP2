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

## Load the neural-network toolbox
pkg load octave-fann

## Load the TORCS simulator functions for drive/control applications
source ../torcs_drive.m

###############################################
# Define helper functions here
###############################################
#Chargement des données provenant des capteurs 
data = load('data/recorded.mat');

###############################################
# Define code logic here
###############################################
## Create neural network
## TODO : Tune the number and size of hidden layers 

# Entrée correspondant aux mesures effectuées par les capteurs
nbInputNodes = size(data,2);

# Nombre de neurones dans la couche cachée. Réaliser des essais avec plusieurs couches cachées 
nbHiddenNodes1 = 2;
#nbHiddenNodes1 = 4;
#nbHiddenNodes1 = 6;
#nbHiddenNodes1 = 8;
#nbHiddenNodes1 = 10;
###############################################
# Création d'autres couches cachées pour les tests 

#nbHiddenNodes2 = 2;
#nbHiddenNodes2 = 4;
#nbHiddenNodes2 = 6;
#nbHiddenNodes2 = 8;
#nbHiddenNodes2 = 10;

#nbHiddenNodes3 = 2;
#nbHiddenNodes3 = 4;
#nbHiddenNodes3 = 6;
#nbHiddenNodes3 = 8;
#nbHiddenNodes3 = 10

###############################################
# Nombre de neurones en sortie (commande de la voiture)
# 4 sorties : acceleration / brake / gear / stear 
nbOutputNodes = size(target,2);
###############################################
## TODO: Load trained neural network
## see function fann_create

# Création du réseau 

# 1 couche de neurones cachés
net = fann_create([nbInputNodes, nbHiddenNodes1, nbOutputNodes]);

# 2 couches de neurones cachés
#net = fann_create([nbInputNodes, nbHiddenNodes1, nbHiddenNodes2, nbOutputNodes]);

# 3 couches de neurones cachés
#net = fann_create([nbInputNodes, nbHiddenNodes1, nbHiddenNodes2, nbHiddenNodes3, nbOutputNodes]);

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
	
		## TODO: construct an input vector from the car state, a structure with the following fields
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
	
		## TODO: evaluate the output of the neural-network for the given input 
		## see function fann_run
    ## Test network (loading from disk)
    net = fann_create("iris.net");
    res = fann_run(net, data);
		## TODO: construct the action, a structure with the following fields:
		##     Adapted from the Software Manual of the Car Racing Competition @ WCCI2008
		##     http://julian.togelius.com/Loiacono2008The.pdf
		##
		##     accel, the virtual gas pedal (0 means no gas, 1 full gas), in the range [0,1].
		##     brake, the virtual brake pedal (0 means no brake, 1 full brake), in the range [0,1].
		##     gear, the gear value. -1 is reverse, 0 is neutral and the forward gear can range from 1 to 6.
		##     steer, the steering value. -1 and +1 means respectively full left and right, that corresponds to an angle of 0.785398 rad.
		
    action = struct();
		action.steer = 0;
		action.gear = 0;
		action.accel = 0;
		action.brake = 0;
	
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
