pvsRequest_PCT <-
	function (request,inputs) {
		pvs.url <- paste("http://api.votesmart.org/",request,"key=",get('pvs.key',envir=.GlobalEnv),inputs,sep="") #generate url for request
		
		httpresp <- GET(url=pvs.url)
		xmltext <- content(x=httpresp, as="text")
		errors <-  getXMLErrors(xmltext) # check if xml can be parsed properly
		
		if (length(errors) != 0) {
			if (names(errors[[1]]$code) == "XML_ERR_CDATA_NOT_FINISHED") { # if not, try to fix 
				xmltext <- gsub(pattern="\003", replacement="", x=xmltext, fixed=TRUE)
			}
		}
		output.base <- xmlRoot(xmlTreeParse(xmltext, useInternalNodes=TRUE))
		
		secs <- "section" %in% names(output.base)
		if (secs) {# Extract PCT survey responses (sections) separately if available:
			
			sections <- xpathApply(output.base, ".//section", xmlChildren)
			section_names <- xpathApply(output.base, ".//section/name", xmlValue)
			
			qas <- lapply(sections, FUN=function(x){
				
				if ("row" %in% names(x) ){
					
					rows <- xmlChildren(x$row)
					nestedrows <- "row" %in% names(rows)
					
					if (!nestedrows) {
						.df <- data.frame( t(xmlSApply(x$row, xmlValue)), stringsAsFactors = FALSE)
					} else {
						mainq <- rows[names(rows)!="row"]
						mainq.df <- data.frame(t(unlist(lapply(mainq, xmlValue), recursive = FALSE)), stringsAsFactors = FALSE)
						rest <- rows[names(rows)=="row"]
						rest.list <- lapply(rest, function(x) data.frame( t(xmlSApply(x, xmlValue)), stringsAsFactors = FALSE))
						rest.df <- bind_rows(rest.list)
						allq <- bind_rows(mainq.df, rest.df)
						
						return(allq)
					}
					
				} else {
					return(data.frame(path="NA"))
				}
			})

			# combine all dfs in qas to one (add names to rows, easier to handle multiple requests...)
			qas <- lapply(1:length(qas), FUN=function(i){
				
				.qa <- qas[[i]]
				n.qa <- names(.qa)
				.qa[, "section"] <- section_names[[i]]
				.qa[,c("section", n.qa)]
				
			})
			
			qas.df <- bind_rows(qas)
			
			# extract rest of the data, add it to the df
			output.baseRest <- removeChildren(output.base,kids=1)[names(output.base)!="section"]
			output <- t(unlist(lapply(output.baseRest, function(x) unlist(xmlSApply(x, xmlValue), recursive = FALSE)), recursive = FALSE))
			output.df <- data.frame(output, row.names=NULL, stringsAsFactors = FALSE)
			names(output.df) <- gsub(".text", "", names(output.df), fixed = TRUE)
			
			return(list(candidate=output.df, survey=qas.df))
			
		} else {# no survey data available --> only return main data
			
			qas.df <- data.frame(section="NA")
			output.base <- xmlRoot(xmlTreeParse(xmltext, useInternalNodes=TRUE))
			output <- t(unlist(xmlSApply(removeChildren(output.base,kids=1), function(x) unlist(xmlSApply(x, xmlValue), recursive = FALSE)), recursive = FALSE))
			output.df <- data.frame(output, row.names=NULL, stringsAsFactors = FALSE)
			names(output.df) <- gsub(".text", "", names(output.df), fixed = TRUE)
			
			return (list(candidate=output.df, survey=qas.df))
		}
	}

