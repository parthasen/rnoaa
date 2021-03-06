% Generated by roxygen2 (4.1.0): do not edit by hand
% Please edit documentation in R/ncdc_plot.r
\name{ncdc_plot}
\alias{ncdc_plot}
\alias{ncdc_plot.ncdc_data}
\title{Plot NOAA climate data.}
\usage{
ncdc_plot(..., breaks = "7 days", dateformat = "\%d/\%m/\%y")

\method{ncdc_plot}{ncdc_data}(..., breaks = "7 days",
  dateformat = "\%d/\%m/\%y")
}
\arguments{
\item{...}{Input noaa object or objects.}

\item{breaks}{Regularly spaced date breaks for x-axis. See \code{\link{date_breaks}}}

\item{dateformat}{Date format using standard POSIX specification for labels on
x-axis. See \code{\link{date_format}}}
}
\value{
Plot of climate data.
}
\description{
This function accepts directly output from the \code{\link[rnoaa]{ncdc}} function,
not other functions.
}
\details{
This is a simple wrapper function around some ggplot2 code. There is indeed a lot you
can modify in your plots, so this function just does some basic stuff. Here's the
code within this function, where input is the output from a \code{\link[rnoaa]{ncdc}}
call - go crazy:

input <- input$data
input$date <- ymd(str_replace(as.character(input$date), "T00:00:00\\.000", ''))
ggplot(input, aes(date, value)) +
   theme_bw(base_size=18) +
   geom_line(size=2) +
   scale_x_datetime(breaks = date_breaks("7 days"), labels = date_format('%d/%m/%y')) +
   labs(y=as.character(input[1,'dataType']), x="Date")
}
\examples{
\dontrun{
# Search for data first, then plot
out <- ncdc(datasetid='GHCND', stationid='GHCND:USW00014895', datatypeid='PRCP',
startdate = '2010-05-01', enddate = '2010-10-31', limit=500)
ncdc_plot(out)
ncdc_plot(out, breaks="14 days")
ncdc_plot(out, breaks="1 month", dateformat="\%d/\%m")
ncdc_plot(out, breaks="1 month", dateformat="\%d/\%m")

out2 <- ncdc(datasetid='GHCND', stationid='GHCND:USW00014895', datatypeid='PRCP',
startdate = '2010-05-01', enddate = '2010-05-03', limit=100)
ncdc_plot(out2, breaks="6 hours", dateformat="\%H")

# Combine many calls to ncdc function
out1 <- ncdc(datasetid='GHCND', stationid='GHCND:USW00014895', datatypeid='PRCP',
startdate = '2010-03-01', enddate = '2010-05-31', limit=500)
out2 <- ncdc(datasetid='GHCND', stationid='GHCND:USW00014895', datatypeid='PRCP',
startdate = '2010-09-01', enddate = '2010-10-31', limit=500)
df <- ncdc_combine(out1, out2)
ncdc_plot(df)
## or pass in each element separately
ncdc_plot(out1, out2, breaks="45 days")
}
}

