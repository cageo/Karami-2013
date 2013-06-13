Corresponding article in Computers and Geosciences:
Using GIS servers and interactive maps in spectral data sharing and administration: Case study of Ahvaz Spectral Geodatabase Platform (ASGP) - 2013
===============================================
Authors: Mojtaba Karami, Kazem Rangzan, Azim Saberi




This repository contains all codes to run spectral processing unit of ASGP:


main.m..............main workflow of the program. See the algorithm flowchart in CAGEO article

FIRSTRUN.m..............at the first run of the program, this script should be used instead of main. 

MetaQ.m..............function for calculation and insertion of MCI for a list of objects

plotandupload.m..............generates spectral plots and updates plot URLs in DB 

importasd.m..............reads ASD signature files

importsvc.m..............reads SVC signature files

asd_processing_workflow.m..............handles processing of ASD spectra using other functions

asd_jumpcorrection.m..............corrects ASD jumps at 1000 nm and 1800 nm, using additive and multiplicative approach

asd_smooth.m..............detects amount of noise and smoothes ASD spectra accordingly

adsmoothdiff.m..............smoothing function

svc_processing_workflow.m..............handles processing of SVC spectra using other functions

svc_removeoverlap.m..............removes overlaps from SVC spectra

upload.m..............function for upload of processed spectral data using REST

maxdate.mat..............modification date of the latest parsed server log file

processedlist.mat..............a list the algorithm keeps of the processed feature objects

speclogo.png..............a logo that the algorithm contains in processed packages. It could also be used to stamp plots

config.txt..............Algorithm parses required parameters from this file. Please note that database connection information (ODBC connection name, username, password) are given within the scripts. 
