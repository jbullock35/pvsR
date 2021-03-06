##' Get a single vote according to official and action
##' 
##' This function is a wrapper for the Votes.getBillActionVoteByOfficial() method of the PVS API Votes class which grabs single vote according to official and action. The function sends a request with this method to the PVS API for all action and candidate IDs given as a function input, extracts the XML values from the returned XML file(s) and returns them arranged in one data frame.
##' @usage Votes.getBillActionVoteByOfficial(actionId, candidateId)
##' @param actionId a character string or list of character strings with the action ID(s) (see references for details)
##' @param candidateId a character string or list of character strings with the candidate ID(s) (see references for details)
##' @return A data frame with a row for each vote and columns with the following variables describing the vote:\cr votes.vote.candidateId,\cr votes.vote.candidateName,\cr votes.vote.officeParties,\cr votes.vote.action.
##' @references http://api.votesmart.org/docs/Votes.html\cr
##' Use Candidates.getByOfficeState(), Candidates.getByOfficeTypeState(), Candidates.getByLastname(), Candidates.getByLevenshtein(), Candidates.getByElection(), Candidates.getByDistrict() or Candidates.getByZip() to get a list of candidate IDs.\cr
##' Use Votes.getBill() or Votes.getByOfficial() to get a list of action IDs.\cr
##' See also: Matter U, Stutzer A (2015) pvsR: An Open Source Interface to Big Data on the American Political Sphere. PLoS ONE 10(7): e0130501. doi: 10.1371/journal.pone.0130501
##' @author Ulrich Matter <ulrich.matter-at-unibas.ch>
##' @examples
##' # First, make sure your personal PVS API key is saved as character string in the pvs.key variable:
##' \dontrun{pvs.key <- "yourkey"}
##' # get information about certain votes
##' \dontrun{vote <- Votes.getBillActionVoteByOfficial(list(28686,31712),9490)}
##' \dontrun{vote}
##' @export


Votes.getBillActionVoteByOfficial <-
	function (actionId, candidateId) {

		# internal function
		Votes.getBillActionVoteByOfficial.basic <- 
			function (.actionId, .candidateId) {

				request <-  "Votes.getBillActionVoteByOfficial?"
				inputs  <-  paste("&actionId=",.actionId,"&candidateId=",.candidateId,sep="")
				output  <-  pvsRequest(request,inputs)
				output$actionId <- .actionId
				output$candidateId <- .candidateId
				
				return(output)
		}  
		
		# Main function  
		output.list <- lapply(actionId, FUN= function (y) {
			lapply(candidateId, FUN= function (s) {
				Votes.getBillActionVoteByOfficial.basic(.actionId=y, .candidateId=s)
			}
			)
		}
		)
		
		output.list <- redlist(output.list)
		output <- bind_rows(output.list)
		
		return(output)
	}
