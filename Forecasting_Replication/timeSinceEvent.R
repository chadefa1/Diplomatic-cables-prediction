#Function to calculate the time since an event
timeSinceEvent <- function(eventSequence){  #eventSequence should be a binary vector of the form eventSequence <- c(0,0,1,0,0,0,0)
  # Create an increasing sequence
  timeSinceEvents <- seq(1,length(eventSequence))
  #when do the events (1s) occur?
  timeOfEvents <- which(eventSequence==1)
  tt=0
  for(w in timeOfEvents){
    if(w<length(timeSinceEvents)){
      timeSinceEvents[(w+1):length(timeSinceEvents)] <- timeSinceEvents[(w+1):length(timeSinceEvents)] - w +tt            
    }
    tt=w
  }
  return(timeSinceEvents)
}



########################################################################
# Calculate time to war
########################################################################
timeToEvent <- function(eventSequence){  #eventSequence should be a binary vector of the form eventSequence <- c(0,0,1,0,0,0,0)
     # reverse the sequence of events
     eventSequence.rev <- rev(eventSequence)
     # Create an increasing sequence
     timeToEvents.tmp <- seq(1,length(eventSequence))
     #when do the events (1s) occur?
     timeOfEvents <- which(eventSequence.rev==1)
     tt=0
     for(w in timeOfEvents){
          timeToEvents.tmp[w:length(timeToEvents.tmp)] <- timeToEvents.tmp[w:length(timeToEvents.tmp)] - w +tt
          tt=w
     }
     #truncate the end
     if(!is.na(timeOfEvents[1]) & timeOfEvents[1]!=1){
          try(timeToEvents.tmp[1:(timeOfEvents[1]-1)] <- NA)
     }
     if(length(timeOfEvents)==0  ){
          timeToEvents.tmp <- rep(NA, length(timeToEvents.tmp))
     }        
     #reverse it back
     timeToEvents <- rev(timeToEvents.tmp)
     return(timeToEvents)
}


