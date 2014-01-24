biovel-nbc
==========

Naturalis implementations of BioVeL services.

Asynchronous API to be implemented
==================================

One endpoint to submit the different jobs, with four parameters: 
* `name` --- required
* `arguments` --- required
* `sessionid` --- optional
* `email` --- optional

*name* differentiates the different types of work, while *arguments* give the info. 
Data are given as URL(s) within *arguments*, which allows multiple submission 
divided by ";". Within phylogenetics service set we are not using yet this multiple 
submission proposed by INFN. The reply of this insertjob is an xml with several tags. 
Example:

	&lt;Job>
		&lt;Name>blast&lt;/Name>
		&lt;Flag>7772590c-d7ab-4b76-98b9-aa293c6c34fe&lt;/Flag>
		&lt;JobsID>
			&lt;JobId>454118&lt;/JobId>
		&lt;/JobsID>
	&lt;/Job>

One endpoint to collect results with one parameter, *jobid*, that identifies the job 
to retrieve. The reply is for example:

	&lt;Jobs>
		&lt;Job>
			&lt;Arguments>
				http://webtest.ba.infn.it/vicario/FinalFusariumDB_2.nex 
				5700.fa 10589.fbsse se selknlk noiho niooih r 
			&lt;/Arguments>
			&lt;Comment>interactive&lt;/Comment>
			&lt;CPUs>7&lt;/CPUs>
			&lt;Flag>2dbbd030-2803-43c0-a21d-369a21e17f2b&lt;/Flag>
			&lt;Id>349177&lt;/Id>
			&lt;LastCheck>2011-11-18 12:54:01.0&lt;/LastCheck>
			&lt;Name>MyBlasts&lt;/Name>
			&lt;Output/>
			&lt;Provenance/>
			&lt;Status>free&lt;/Status>
		&lt;/Job>
	&lt;/Jobs>

The workflow is looking for these paths:

1. `/Jobs/Job/Status` --- and check if is equal to "done"
2. `/Jobs/Job/Output`  to collect the body that could be or an xml or url or a base64 
   encoded string. Generally is a url with bulk information not relevant for the taverna 
   engine but to pass on to next webservice.
3. `/Jobs/Job/StandardOutput` to collect the body that could be or an xml or url or a 
   base64 enconded string. Generally is a xml with information to be processed within the 
   taverna engine
4. `/Jobs/Job/StandardError` to collect the body that is a base64 encoded string with 
   all relevant info for debug error
