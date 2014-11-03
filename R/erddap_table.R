#' Get ERDDAP tabledap data.
#'
#' @export
#' @import httr assertthat
#'
#' @param datasetid Dataset id
#' @param ... Any number of key-value pairs in quotes as query constraints. See Details & examples
#' @param fields Columns to return, as a character vector
#' @param distinct If TRUE ERDDAP will sort all of the rows in the results table (starting with the
#' first requested variable, then using the second requested variable if the first variable has a
#' tie, ...), then remove all non-unique rows of data. In many situations, ERDDAP can return
#' distinct values quickly and efficiently. But in some cases, ERDDAP must look through all rows
#' of the source dataset.
#' @param orderby If used, ERDDAP will sort all of the rows in the results table (starting with the
#' first variable, then using the second variable if the first variable has a tie, ...). Normally,
#' the rows of data in the response table are in the order they arrived from the data source.
#' orderBy allows you to request that the results table be sorted in a specific way. For example,
#' use \code{orderby=c("stationID,time")} to get the results sorted by stationID, then time. The
#' orderby variables MUST be included in the list of requested variables in the fields parameter.
#' @param orderbymax Give a vector of one or more fields, that must be included in the fields
#' parameter as well. Gives back data given constraints. ERDDAP will sort all of the rows in the
#' results table (starting with the first variable, then using the second variable if the first
#' variable has a tie, ...) and then just keeps the rows where the value of the last sort variable
#' is highest (for each combination of other values).
#' @param orderbymin Same as \code{orderbymax} parameter, except returns minimum value.
#' @param orderbyminmax Same as \code{orderbymax} parameter, except returns two rows for every
#' combination of the n-1 variables: one row with the minimum value, and one row with the maximum
#' value.
#' @param units One of 'udunits' (units will be described via the UDUNITS standard (e.g.,degrees_C))
#' or 'ucum' (units will be described via the UCUM standard (e.g., Cel)).
#' @param callopts Further args passed on to httr::GET (must be a named parameter)
#'
#' @details
#' For key-value pair query constraints, the valid operators are =, != (not equals), =~ (a regular
#' expression test), <, <=, >, and >= . For regular expressions you need to add a regular
#' expression. For others, nothing more is needed. Construct the entry like
#' \code{'time>=2001-07-07'} with the parameter on the left, value on the right, and the operator
#' in the middle, all within a set of quotes. Since ERDDAP accepts values other than \code{=}, we
#' can't simply do \code{time = '2001-07-07'} as we normally would.
#'
#' Server-side functionality: Some tasks are done server side. You don't have to worry about what
#' that means. They are provided via parameters in this function. See \code{distinct},
#' \code{orderby}, \code{orderbymax}, \code{orderbymin}, \code{orderbyminmax}, and \code{units}.
#'
#' @examples \dontrun{
#' # Just passing the datasetid without fields gives all columns back
#' out <- erddap_table(datasetid='erdCalCOFIfshsiz')
#' nrow(out)
#'
#' # Pass time constraints
#' head(erddap_table(datasetid='erdCalCOFIfshsiz', 'time>=2001-07-07', 'time<=2001-07-08'))
#'
#' # Pass in fields (i.e., columns to retrieve) & time constraints
#' erddap_table(datasetid='erdCalCOFIfshsiz',fields=c('longitude','latitude','fish_size','itis_tsn'),
#'    'time>=2001-07-07','time<=2001-07-10')
#' erddap_table(datasetid='erdCinpKfmBT', fields=c('latitude','longitude',
#'    'Aplysia_californica_Mean_Density','Muricea_californica_Mean_Density'),
#'    'time>=2007-06-24','time<=2007-07-01')
#'
#' # Get info on a datasetid, then get data given information learned
#' erddap_info('erdCalCOFIlrvsiz')$variables
#' erddap_table(datasetid='erdCalCOFIlrvsiz', fields=c('latitude','longitude','larvae_size',
#'    'itis_tsn'), 'time>=2011-10-25', 'time<=2011-10-31')
#'
#' # An example workflow
#' ## Search for data
#' (out <- erddap_search(query='fish size'))
#' ## Using a datasetid, search for information on a datasetid
#' id <- out$info$dataset_id[1]
#' erddap_info(datasetid=id)$variables
#' ## Get data from the dataset
#' head(erddap_table(datasetid = id, fields = c('latitude','longitude','scientific_name')))
#'
#' # Time constraint
#' ## Limit by time with date only
#' erddap_table(datasetid = id, fields = c('latitude','longitude','scientific_name'),
#'    'time>=2001-07-14')
#' ## Limit by time with hours and date
#' erddap_table(datasetid='ndbcSosWTemp', fields=c('latitude','longitude','sea_water_temperature'),
#'    'time>=2014-05-14T15:15:00Z')
#'
#' # Use distinct parameter
#' erddap_table(datasetid='erdCalCOFIfshsiz',fields=c('longitude','latitude','fish_size','itis_tsn'),
#'    'time>=2001-07-07','time<=2001-07-10', distinct=TRUE)
#'
#' # Use units parameter
#' ## In this example, values are the same, but sometimes they can be different given the units
#' ## value passed
#' erddap_table(datasetid='erdCinpKfmT', fields=c('longitude','latitude','time','temperature'),
#'    'time>=2007-09-19', 'time<=2007-09-21', units='udunits')
#' erddap_table(datasetid='erdCinpKfmT', fields=c('longitude','latitude','time','temperature'),
#'    'time>=2007-09-19', 'time<=2007-09-21', units='ucum')
#'
#' # Use orderby parameter
#' erddap_table(datasetid='erdCinpKfmT', fields=c('longitude','latitude','time','temperature'),
#'    'time>=2007-09-19', 'time<=2007-09-21', orderby='temperature')
#' # Use orderbymax parameter
#' erddap_table(datasetid='erdCinpKfmT', fields=c('longitude','latitude','time','temperature'),
#'    'time>=2007-09-19', 'time<=2007-09-21', orderbymax='temperature')
#' # Use orderbymin parameter
#' erddap_table(datasetid='erdCinpKfmT', fields=c('longitude','latitude','time','temperature'),
#'    'time>=2007-09-19', 'time<=2007-09-21', orderbymin='temperature')
#' # Use orderbyminmax parameter
#' erddap_table(datasetid='erdCinpKfmT', fields=c('longitude','latitude','time','temperature'),
#'    'time>=2007-09-19', 'time<=2007-09-21', orderbyminmax='temperature')
#' # Use orderbymin parameter with multiple values
#' erddap_table(datasetid='erdCinpKfmT',fields=c('longitude','latitude','time','depth','temperature'),
#'    'time>=2007-06-10', 'time<=2007-09-21', orderbymax=c('depth','temperature'))
#'
#' # Spatial delimitation
#' erddap_table(datasetid = 'erdCalCOFIfshsiz', fields = c('latitude','longitude','scientific_name'),
#'  'latitude>=34.8', 'latitude<=35', 'longitude>=-125', 'longitude<=-124')
#'
#' # Integrate with taxize
#' out <- erddap_table(datasetid = 'erdCalCOFIfshsiz',
#'    fields = c('latitude','longitude','scientific_name','itis_tsn'))
#' tsns <- unique(out$itis_tsn[1:100])
#' library("taxize")
#' classif <- classification(tsns, db = "itis")
#' head(rbind(classif)); tail(rbind(classif))
#' }

erddap_table <- function(datasetid, ..., fields=NULL, distinct=FALSE, orderby=NULL,
  orderbymax=NULL, orderbymin=NULL, orderbyminmax=NULL, units=NULL, callopts=list())
{
  fields <- paste(fields, collapse = ",")
  url <- "http://coastwatch.pfeg.noaa.gov/erddap/tabledap/%s.csv?%s"
  url <- sprintf(url, datasetid, fields)
  args <- list(...)
  distinct <- if(distinct) 'distinct()' else NULL
  units <- if(!is.null(units)) makevar(toupper(units), 'units("%s")') else units
  orderby <- makevar(orderby, 'orderBy("%s")')
  orderbymax <- makevar(orderbymax, 'orderByMax("%s")')
  orderbymin <- makevar(orderbymin, 'orderByMin("%s")')
  orderbyminmax <- makevar(orderbyminmax, 'orderByMinMax("%s")')
  moreargs <- noaa_compact(list(distinct, orderby, orderbymax, orderbymin, orderbyminmax, units))
  args <- c(args, moreargs)
  args <- paste0(args, collapse = "&")
  if(!nchar(args[[1]]) == 0){
    url <- paste0(url, '&', args)
  }
  tt <- GET(url, list(), callopts)
  out <- check_response_erddap(tt)
  if(grepl("Error", out)){
    return( NA )
  } else {
    df <- read.delim(text=out, sep=",", stringsAsFactors=FALSE)[-1,]
    df
  }
}

makevar <- function(x, y){
  if(!is.null(x)){
    x <- paste0(x, collapse = ",")
    sprintf(y, x)
  } else {
    NULL
  }
}