biovel-nbc
==========

Naturalis implementations of BioVeL services.

Contributors
============
* Bachir Balech (bitbucket: bachirb)
* Rutger Vos, @rvosa
* Christian Brenninkmeijer, @Christian-B
* Hannes Hettling, @hettling
* David King, @DauvitKing

Aims
====
* To develop command-line tools that merge data in a number of commonly-used phylogenetic 
file formats and export them as [http://nexml.org NeXML]: the Merger service.
* To develop command-line tools that extract objects from NeXML data: Taxa, Trees, 
Character matrices, all with metadata embedded: the Extractor service.
* To wrap these tools inside Taverna-compatible RESTful services.
* To publish these services on [http://BiodiversityCatalogue.org BiodiversityCatalogue].
* To annotate these services according to [http://biovel.eu BioVeL] guidelines.

The Merger service
==================
Inputs
------
* Phylogenetic trees, in at least the following formats: Newick, NEXUS, PhyloXML, NeXML. 
There are two parameters for specifying trees, the location (`trees={URL}`),  
and the syntax format (`treeformat={Newick|NEXUS|PhyloXML|NeXML}`).
* Alignments, in at least the following formats: PHYLIP, NEXUS, NeXML, FASTA. There are 
three parameters for each alignment file, the location (`data={URL}`), the 
syntax format (`dataformat={PHYLIP|NEXUS|NeXML|FASTA}`), and, optionally, the 
data type (`datatype={dna|protein|standard}`, default is dna).
* Character sets, in text format, i.e. `charsets={URL}`, 
`charsetformat={nexus|txt}`.
* Metadata in JSON or TSV syntax. i.e. `meta={URL}`, 
`metaformat={JSON|TSV}`. The first column of the metadata identifies which 
object is annotated. We can distinguish the following objects: `TaxonID, AlignmentID, 
TreeID, NodeID, SiteID, CharacterID`

Output
------
* A NeXML document.

URL API
-------
* The service responds to HTTP GET requests, so all parameters are combined in the 
QUERY_STRING, with all "dangerous" characters URL-escaped.

The Extractor service
=====================
Inputs
------
* NeXML file, whose location is specified as a URL, e.g. `nexml={URL}`
* A parameter that specifies which objects to extract, e.g. 
`objects={Taxa|Trees|Matrices}`
* A parameter that specifies the output formats, 
`treeformat={NEXUS|Newick|PhyloXML|NeXML}`, 
`dataformat={NEXUS|PHYLIP|FASTA|Stockholm}`, 
`metaformat={tsv|JSON|csv}`, `charsetformat={txt}`

Output
------
* A subset of the NeXML data in the requested format, with a separate download of the 
metadata, likewise in the requested format.

Service deployment
==================
We deploy the services as [http://perl.apache.org mod_perl] handlers, which means that for 
synchronous services (i.e. everything is done in one request/response cycle) no forking is 
done at all. For asynchronous servers, the service class doesn't have to keep track of its 
session: the superclass keeps track of serializing and de-serializing the job object 
between requests.

Links
=====
* [https://github.com/naturalis/biovel-nbc Naturalis BioVeL github repo]
* [http://biovel.eu BioVeL]
* [http://biodiversitycatalogue.org BiodiversityCatalogue]
* [http://nexml.org NeXML]
* [http://taverna.org.uk Taverna]
* [http://build.mygrid.org.uk/ci/job/taverna-workbench-enterprise/7/net.sf.taverna.t2.taverna-workbench$taverna-workbench-enterprise/artifact/net.sf.taverna.t2.taverna-workbench/taverna-workbench-enterprise/2.5-SNAPSHOT/ Taverna 2.5Snapshot]
* [http://dev.mygrid.org.uk/wiki/display/taverna/Loops Taverna Looping]