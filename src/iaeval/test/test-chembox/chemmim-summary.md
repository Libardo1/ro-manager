# Comparing MiM and Minim in the context of ChemMim requirements

Note: to convert to HTML with ToC, use:

        pandoc --table-of-contents --toc-depth=3 -c pandoc-html.css \
               --from=markdown --to=html \
               -o chemmim-summary.html chemmim-summary.md

# MiM requirements

Each MiM requirement is expressed in two parts:

1. A SPARQL CONSTRUCT query or queries (expressed in RDF using the SPIN vocabulary) that are used as rules to infer reported values in some common vocabulary from annotations provided using an application-specific vocabulary (e.g. chembox).
2. A MiM requirement which associates a requirement level (MUST/SHOULD/MAY) with a particular report, and may place additional cardinality / type constraints on the reported value(s).

A reported value has the following general form:

    :someResource mim:containsDataReport
      [ mim:reports   :someReport ;
        mim:withValue :someValue ] .

We see such requirements constructed using thee levels of vocabulary:

* MiM and and other domain-independent vocabularies (e.g. SPIN, RDF, XSD, etc.).
* Requirement-specific vocabularies used to define the requirements (e.g. ChemMim)
* Application-specific vocabularies that relate to the specific instance data being analyzed (e.g. ChemBox).  Different such vocabularies may be used (along with matching SPIN rules) to bring together requirements that are reported by different applications.

A complete minimum information model is expressed as a set of requirements.  These ideas are expressed in the representative examples of requirements in the following five sub-sections.

# Summary of ChemMim requirement patterns using Mim and Minim

## Synonym (simple optional requirement)

This is a simple MAY requirement:

    :MIM  rdf:type mim:MIM ;
          mim:hasOptionalRequirement  :Synonym .

The report is generated by the following SPARQL query (encoded in the RDF metadata using SPIN vocabulary):

    CONSTRUCT
      { ?x mim:containsDataReport _:b0 .
        _:b0 mim:reports chembox-mim:Synonym .
        _:b0 mim:withValue ?value . }
    WHERE
      { ?x chembox:OtherNames ?value . }

The same requirement would be expressed in Minim thus:

    :minim_checklist rdf:type minim:Model ;
      rdfs:label "A Minim checklist"
      rdfs:comment "..." ;
      minim:hasMayRequirement  :Synonym .

    :Synonym rdf:type minim:Requirement
       minim:isDerivedBy
        [ rdf:type minim:ContentMatchRequirementRule ;
          minim:exists
            """
            ?x chembox:OtherNames ?value .
            """
          minim:showpass "Synonym is present" ;
          minim:showfail "No synonym is present" ;
        ] .

where the value of `minim:exists` is the body of a SPARQL ASK query.  The MiM rule that reports a value and the requirement that the value be reported are combined here into a single `minim:Requirement` structure.


## InChI (datatype checking)

This is a requirement that an InChI identifier MUST be present, and also that it must be a string.

    :MIM  rdf:type mim:MIM ;
          mim:hasMustRequirement      :Identifiers .
          mim:hasRestriction
            [ mim:exactCardinality 1 ;
              mim:onRequirement       :Identifiers ] ;
    
    :Identifiers
          rdf:type mim:RequirementSet ;
          mim:hasMustRequirement      :InChI .

    :InChI
          rdf:type mim:DataRequirement ;
          mim:hasRestriction
                  [ mim:onSelf "true"^^xsd:boolean ;
                    mim:type xsd:string ] .

@@TODO: I'm awaiting feedback about how the requirement levels and restrictions interact with/through requirement sets.

The InChI value itself is determined by this query (expressed here as SPARQL, but encoded in MiM as SPIN):

    CONSTRUCT 
        { ?x mim:containsDataReport _:b0 .
          _:b0 mim:reports chembox-mim:InChI .
          _:b0 mim:withValue ?value . }
    WHERE { ?x chembox:StdInChI ?value . }

The same requirement would be expressed in a Minim requirement thus (not incorporating the cardinality constraint):

    :minim_checklist rdf:type minim:Model ;
      rdfs:label "A Minim checklist"
      rdfs:comment "..." ;
      minim:hasMustRequirement  :InChI .
    
    :InChI rdf:type minim:Requirement
       minim:isDerivedBy
        [ rdf:type minim:ContentMatchRequirementRule ;
          minim:exists
            """
            ?x chembox:StdInChI ?value .
            FILTER ( datatype(?value) == xsd:string )
            """
          minim:showpass "InChI identifier is present" ;
          minim:showfail "No InChI identifier is present" ;
        ] .

In the Minim case, the datatype checking is performed within the SPARQL query.  The current version of the checklist tool does not support this, as the datatype function is not supported by the SPARQL query engine used.


## ChemSpider (integer value)

This is an optional requirement whose value, if present, must be an integer.  On the surface, it seems to me this could be handled in much the same way as the InChI value (with an appropriately modified definition of `mim:type` to work in the lexical space rather than the value space of a datatype), but here the value is reported as an integer.

    :MIM  rdf:type mim:MIM ;
          mim:hasMustRequirement      :Identifiers ;
          mim:hasRestriction
            [ mim:exactCardinality 1 ;
              mim:onRequirement       :Identifiers ] .
    
    :Identifiers
          rdf:type mim:RequirementSet ;
          mim:hasShouldRequirement    :ChemSpider .

    :ChemSpider
          rdf:type mim:DataRequirement ;
          mim:hasRestriction
                  [ mim:onSelf "true"^^xsd:boolean ;
                    mim:type xsd:integer ] .

@@TODO: I'm awaiting feedback about how the requirement levels and restrictions interact with/through requirement sets.

The construction here is similar to :InChI, except that the query attempts to bind the reported value as an integer:

    CONSTRUCT
        { ?x mim:containsDataReport _:b0 .
         _:b0 mim:reports chembox-mim:ChemSpider .
         _:b0 mim:withValue ?value . }
    WHERE 
        { ?x chembox:ChemSpiderID ?c .
          BIND (xsd:integer(?c) AS ?cd) .
          BIND (IF(bound(?cd), ?cd, ?c) AS ?value) . }

The same requirement would be expressed in a Minim requirement thus (not incorporating the cardinality constraint):

    :minim_checklist rdf:type minim:Model ;
      rdfs:label "A Minim checklist"
      rdfs:comment "..." ;
      minim:hasShouldRequirement  :ChemSpider .
    
    :ChemSpider rdf:type minim:Requirement
       minim:isDerivedBy
        [ rdf:type minim:ContentMatchRequirementRule ;
          minim:exists
            """
            ?x chembox:ChemSpiderID ?value .
            FILTER ( str(xsd:integer(?value)) )
            """
          minim:showpass "ChemSpider identifier is present" ;
          minim:showfail "No ChemSpider identifier is present" ;
        ] .

Note: "FILTERs eliminate any solutions that, when substituted into the expression, either result in an effective boolean value of false or produce an error" -- http://www.w3.org/TR/rdf-sparql-query/#tests.  Thus, only valid integers will be accepted.

@@TODO: check that current SPARQL engine supports xsd:integer and str functions.


## MeltingPoint (numeric value with units)

This is an optional requirement whose value, if present, must contain a number and a unit value.

    :MIM  rdf:type mim:MIM ;
          mim:hasMustRequirement      :Properties ;
          mim:hasRestriction
            [ mim:exactCardinality 1 ;
              mim:onRequirement       :Properties ] .
    
    :Properties
          rdf:type mim:RequirementSet ;
          mim:hasShouldRequirement    :MeltingPoint .

    :MeltingPoint
        rdf:type mim:RequirementSet ;
        mim:hasMustRequirement :MeltingPointUnits , :MeltingPointValue ;
        mim:hasRestriction
          [ mim:exactCardinality 1 ;
            mim:onRequirement :MeltingPointUnits , :MeltingPointValue ] .

    :MeltingPointUnits
        rdf:type mim:DataRequirement . 

    :MeltingPointValue
        rdf:type mim:DataRequirement .

@@TODO: I'm awaiting feedback about how the requirement levels and restrictions interact with/through requirement sets.

This involves a relatively complex query that generates three separate reports as required: a :MeltingPoint report, and :MeltingPointUnits and :MeltingPointValue reports, of which there must be exactly one of each.  (Here, we see a mim:RequirementSet value is generated directly by the SPIN rule, which is a little surprising.)

    CONSTRUCT
      { ?x mim:containsReportSet _:b0 .
        _:b0 mim:containsDataReport _:b1 .
        _:b0 mim:containsDataReport _:b2 .
        _:b0 mim:reports chembox-mim:MeltingPoint .
        _:b1 mim:reports chembox-mim:MeltingPointValue .
        _:b1 mim:withValue ?value .
        _:b2 mim:reports chembox-mim:MeltingPointUnits .
        _:b2 mim:withValue ?units . }
    WHERE
      { OPTIONAL
          { ?x (chembox:MeltingPtK|chembox:MeltingPtKL)|chembox:MeltingPtKH ?value .
            BIND ("K" AS ?units) . } .
        OPTIONAL
          { ?x (chembox:MeltingPtC|chembox:MeltingPtCL)|chembox:MeltingPtCH ?value .
            BIND ("C" AS ?units) . } .
      }

Assuming SPARQL 1.1 path expression support, this might be represented in Minim thus (not incorporating the cardinality constraint):

    :MeltingPoint rdf:type minim:Requirement
       minim:isDerivedBy
        [ rdf:type minim:ContentMatchRequirementRule ;
          minim:exists
            """
              { ?x (chembox:MeltingPtK|chembox:MeltingPtKL)|chembox:MeltingPtKH ?value }
            UNION
              { ?x (chembox:MeltingPtC|chembox:MeltingPtCL)|chembox:MeltingPtCH ?value }
            """
          minim:showpass "MeltingPoint is present" ;
          minim:showfail "No MeltingPoint is present" ;
        ] .

This could be expressed equivalently using SPARQL 1.0 as a 6-way UNION query.


## MolecularFormula (complex)

This final example in the chemmim example uses a very complex SPARQL query that appears to attempt to validate a chemical formula expressed as RDF.  The example is sufficiently complex that I don't understand what it is trying to achieve, so I'm assuming that it is not expressible using minim.

    :MIM  rdf:type mim:MIM ;
          mim:hasMustRequirement      :Properties ;
          mim:hasRestriction
            [ mim:exactCardinality 1 ;
              mim:onRequirement       :Properties ] .
    
    :Properties
          rdf:type mim:RequirementSet ;
          mim:hasMustRequirement      :MolecularFormula ;
          mim:hasRestriction
            [ mim:exactCardinality 1 ;
              mim:onRequirement       :MolecularFormula ] .
    
    :MolecularFormula
          rdf:type mim:DataRequirement ;
          mim:hasRestriction
                  [ mim:onSelf "true"^^xsd:boolean ;
                    mim:type xsd:string
                  ] .

@@TODO chat with Matt to find out what is being tested here


# Comparison of MiM and Minim capabilities

A Minim checklist description conflates the notions of requirement and report that are expressed separately in MiM.

Also, the Minim checklist assumes that it is being evaluated against metadata from the bounded context of a Research Object.  By comparison, through the intermediate generation of reports, MiM could support different ways for scoping the appearance of a report.  Also, the MiM approach of reporting a value could be used for creating more informative diagnostic messages (though this is something that MiM does not itself appear to support in itself).

There appear to be just three patterns in the ChemMim evaluation that are not supported by the current Minim implementation:

* Cardinality constraints
* Datatype constraints
* Molecular formula validation

Conversely, the following features of Minim appear to be not obviously supported by MiM

* Liveness testing: Minim is able to perform tests that probe the wider web, such as liveness testing of referenced resource.  I'm not aware of any mechanism on MiM for allowing such tests.
* "Universal" testing (forall <pattern> satisfy <test>), though maybe some of these could be done with SPIN/SPARQL 1.1 subqueries.  Even if these can be supported using SPARQL alone, I would expect the constructions to be awkward and difficult to follow
** @@TODO: discuss whether thius is a real restriction of MiM
* Aggregation testing: this is RO specific, and I think MiM could query the RO aggregation properties to achieve a similar effect.
* Multiple models and model selection.  This is probably best considered to be a separate issue.  I think an equivalent mechanism could be built around MiMs reporting structure, applying extra tests to the subject of generated `mim:containsDataReport` statements.


## Cardinality constraints

Cardinality constraints are not directly supported by Minim, but in some cases it might be possible to achieve a similar effect using SPARQL 1.1 sub-queries and filters.  In practice, it might be easier to introduce additional Minim properties that are used as alternatives to the current minim:exists queries; e.g.

    minim:cardinality
      minim:min 1 ;
      minim:probe "
        """
        ?x chembox:OtherNames ?value .
        """

could be treated as equivalent in its outcome to:

    minim:exists
      """
      ?x chembox:OtherNames ?value .
      """

though the implementation may be less efficient.


## Datatype constraints

In principle, datatype constraints can be handled in Minim using `datatype()` functions in SPARQL filters, but the current implementation does not support these.  There is a new SPARQL query engine for rdflib (the library used by the checklist service) which may support this function.

Alternatively, by adding a MiM-style reporting-rule layer to Minim, values could be made visible for testing in the Minim model.


## Molecular formula validation

@@TODO need to understand what this is actually doing.  It is possible that it can be handled by SPARQL probe queries in Minim, but in this case the queries are clumsy


# Summary of chemmim requirements

## Preliminaries (grouped requirements)

Requirements are grouped roughly into identifiers, properties, and other requirements.

    :MIM  rdf:type mim:MIM ;
          mim:hasMustRequirement      :Properties, :Identifiers ;
          mim:hasShouldRequirement    :IUPACName, :Image .
          mim:hasOptionalRequirement  :Synonym ;
          mim:hasRestriction
            [ mim:exactCardinality 1 ;
              mim:onRequirement       :Properties, :Identifiers ] ;
    
    :Identifiers
          rdf:type mim:RequirementSet ;
          mim:hasMustRequirement      :InChI , :SMILES ;
          mim:hasShouldRequirement    :ChemSpider, :PubChem .
    
    :Properties
          rdf:type mim:RequirementSet ;
          mim:hasMustRequirement      :MolecularFormula ;
          mim:hasShouldRequirement    :MeltingPoint , :MolarMass .
          mim:hasOptionalRequirement  :Solubility ;
          mim:hasRestriction
            [ mim:exactCardinality 1 ;
              mim:onRequirement       :MolecularFormula ] ;


## Identifiers

### InChI

    :InChI
          rdf:type mim:DataRequirement ;
          mim:hasRestriction
                  [ mim:onSelf "true"^^xsd:boolean ;
                    mim:type xsd:string ] .

An InChI identifier must be present, defined by way of a chembox:StdInChI property on some target resource and its value must be a string.  The SPIN rules in chembox-spin.ttl define this mapping from source data to the :InChI requirement; e.g. here's the core of the SPIN rule converted to SPARQL:

    CONSTRUCT 
        { ?x mim:containsDataReport _:b0 .
          _:b0 mim:reports chembox-mim:InChI .
          _:b0 mim:withValue ?value . }
    WHERE { ?x chembox:StdInChI ?value . }

I think the mim:hasRestriction is asserting that the value of the chembox:StdInChI value must be a string for the report to satisfy the requirement.


### SMILES

    :SMILES
          rdf:type mim:DataRequirement ;
          mim:hasRestriction
                  [ mim:onSelf "true"^^xsd:boolean ;
                    mim:type xsd:string ] .

This has almost identical construction to the :InChI requirement.


### ChemSpider

    :ChemSpider
          rdf:type mim:DataRequirement ;
          mim:hasRestriction
                  [ mim:onSelf "true"^^xsd:boolean ;
                    mim:type xsd:integer ] .

The construction here is similar to :InChI, except that the ChemSpider identifier is required to be an integer.

    CONSTRUCT
        { ?x mim:containsDataReport _:b0 .
         _:b0 mim:reports chembox-mim:ChemSpider .
         _:b0 mim:withValue ?value . }
    WHERE 
        { ?x chembox:ChemSpiderID ?c .
          BIND (xsd:integer(?c) AS ?cd) .
          BIND (IF(bound(?cd), ?cd, ?c) AS ?value) . }


### PubChem

    :PubChem
          rdf:type mim:DataRequirement ;
          mim:hasRestriction
                  [ mim:onSelf "true"^^xsd:boolean ;
                    mim:type xsd:integer ] .

This has almost identifcal construction to the :ChemSpider requirement.

    CONSTRUCT
        { ?x mim:containsDataReport _:b0 .
          _:b0 mim:reports chembox-mim:PubChem .
          _:b0 mim:withValue ?value . }
    WHERE
        { ?x chembox:PubChem ?c .
          BIND (xsd:integer(?c) AS ?cd) .
          BIND (IF(bound(?cd), ?cd, ?c) AS ?value) . }


## Properties

### MolecularFormula

    :MolecularFormula
          rdf:type mim:DataRequirement ;
          mim:hasRestriction
                  [ mim:onSelf "true"^^xsd:boolean ;
                    mim:type xsd:string
                  ] .

There's a very simple form for this requirement which simply looks for a chembox:Formula statement in the data.  Minim can handle this easily enough.

    CONSTRUCT
        { ?x mim:containsDataReport _:b0 .
          _:b0 mim:reports chembox-mim:MolecularFormula .
          _:b0 mim:withValue ?value . }
    WHERE
        { ?x chembox:Formula ?value . }

There's also a more complex form that defeats me, which seems to expect a chemical formula in which the constituent chemical elements are described in some RDF structure:  

* the SPIN converter service isn't capable of fully converting the query used: I think it's returning the SELECT subquery, but not the surrounding CONSTRUCT query
* the query itself seems to be attempting to perform a complex string manipulation function that, frankly, I think is unreasonable to attempt using SPARQL.  It seems to be trying to parse and/or assemble a chemical formula.

To handle this in Minim, I would consider introducing a specialized web service to manipulate the formula and return the desired result.  This will require a minim extension to use external services, but one that would be available to address many of these domain-specific considerations.  (Using a functional language to handle the domain specific service implementation could retain a level of logical tractability, but that's a separate issue.  Or simply associate some primitive assertions with the service which can be associated with the result.)

Here is part of the query used for :MolecularFormula:

    PREFIX chembox: <http://dbpedia.org/resource/Template:Chembox:>
    PREFIX fn: <http://www.w3.org/2005/xpath-functions#>
    SELECT *
    WHERE
        { OPTIONAL { ?x chembox:C ?C . } .
          OPTIONAL { ?x chembox:H ?H . } .
          OPTIONAL { ?x chembox:Ac ?Ac . } .
          OPTIONAL { ?x chembox:Ag ?Ag . } .
          OPTIONAL { ?x chembox:Al ?Al . } .
          OPTIONAL { ?x chembox:Am ?Am . } .
          OPTIONAL { ?x chembox:Ar ?Ar . } .
          OPTIONAL { ?x chembox:As ?As . } .
          OPTIONAL { ?x chembox:At ?At . } .
          OPTIONAL { ?x chembox:Au ?Au . } .
          OPTIONAL { ?x chembox:B ?B . } .
          OPTIONAL { ?x chembox:Ba ?Ba . } .
          OPTIONAL { ?x chembox:Be ?Be . } .
          OPTIONAL { ?x chembox:Bh ?Bh . } .
          OPTIONAL { ?x chembox:Bi ?Bi . } .
          OPTIONAL { ?x chembox:Bk ?Bk . } .
          OPTIONAL { ?x chembox:Br ?Br . } .
          OPTIONAL { ?x chembox:Ca ?Ca . } .
          OPTIONAL { ?x chembox:Cd ?Cd . } .
          OPTIONAL { ?x chembox:Ce ?Ce . } .
          OPTIONAL { ?x chembox:Cf ?Cf . } .
          OPTIONAL { ?x chembox:Cl ?Cl . } .
          OPTIONAL { ?x chembox:Cm ?Cm . } .
          OPTIONAL { ?x chembox:Co ?Co . } .
          OPTIONAL { ?x chembox:Cr ?Cr . } .
          OPTIONAL { ?x chembox:Cs ?Cs . } .
          OPTIONAL { ?x chembox:Cu ?Cu . } .
          OPTIONAL { ?x chembox:Db ?Db . } .
          OPTIONAL { ?x chembox:Ds ?Ds . } .
          OPTIONAL { ?x chembox:Dy ?Dy . } .
          OPTIONAL { ?x chembox:Er ?Er . } .
          OPTIONAL { ?x chembox:Es ?Es . } .
          OPTIONAL { ?x chembox:Eu ?Eu . } .
          OPTIONAL { ?x chembox:F ?F . } .
          OPTIONAL { ?x chembox:Fe ?Fe . } .
          OPTIONAL { ?x chembox:Fm ?Fm . } .
          OPTIONAL { ?x chembox:Fr ?Fr . } .
          OPTIONAL { ?x chembox:Ga ?Ga . } .
          OPTIONAL { ?x chembox:Gd ?Gd . } .
          OPTIONAL { ?x chembox:Ge ?Ge . } .
          OPTIONAL { ?x chembox:He ?He . } .
          OPTIONAL { ?x chembox:Hf ?Hf . } .
          OPTIONAL { ?x chembox:Hg ?Hg . } .
          OPTIONAL { ?x chembox:Ho ?Ho . } .
          OPTIONAL { ?x chembox:Hs ?Hs . } .
          OPTIONAL { ?x chembox:I ?I . } .
          OPTIONAL { ?x chembox:In ?In . } .
          OPTIONAL { ?x chembox:Ir ?Ir . } .
          OPTIONAL { ?x chembox:K ?K . } .
          OPTIONAL { ?x chembox:Kr ?Kr . } .
          OPTIONAL { ?x chembox:La ?La . } .
          OPTIONAL { ?x chembox:Li ?Li . } .
          OPTIONAL { ?x chembox:Lr ?Lr . } .
          OPTIONAL { ?x chembox:Lu ?Lu . } .
          OPTIONAL { ?x chembox:Md ?Md . } .
          OPTIONAL { ?x chembox:Mg ?Mg . } .
          OPTIONAL { ?x chembox:Mn ?Mn . } .
          OPTIONAL { ?x chembox:Mo ?Mo . } .
          OPTIONAL { ?x chembox:Mt ?Mt . } .
          OPTIONAL { ?x chembox:N ?N . } .
          OPTIONAL { ?x chembox:Na ?Na . } .
          OPTIONAL { ?x chembox:Nb ?Nb . } .
          OPTIONAL { ?x chembox:Nd ?Nd . } .
          OPTIONAL { ?x chembox:Ne ?Ne . } .
          OPTIONAL { ?x chembox:Ni ?Ni . } .
          OPTIONAL { ?x chembox:No ?No . } .
          OPTIONAL { ?x chembox:Np ?Np . } .
          OPTIONAL { ?x chembox:O ?O . } .
          OPTIONAL { ?x chembox:Os ?Os . } .
          OPTIONAL { ?x chembox:P ?P . } .
          OPTIONAL { ?x chembox:Pa ?Pa . } .
          OPTIONAL { ?x chembox:Pb ?Pb . } .
          OPTIONAL { ?x chembox:Pd ?Pd . } .
          OPTIONAL { ?x chembox:Pm ?Pm . } .
          OPTIONAL { ?x chembox:Po ?Po . } .
          OPTIONAL { ?x chembox:Pr ?Pr . } .
          OPTIONAL { ?x chembox:Pt ?Pt . } .
          OPTIONAL { ?x chembox:Pu ?Pu . } .
          OPTIONAL { ?x chembox:Ra ?Ra . } .
          OPTIONAL { ?x chembox:Rb ?Rb . } .
          OPTIONAL { ?x chembox:Re ?Re . } .
          OPTIONAL { ?x chembox:Rf ?Rf . } .
          OPTIONAL { ?x chembox:Rg ?Rg . } .
          OPTIONAL { ?x chembox:Rh ?Rh . } .
          OPTIONAL { ?x chembox:Rn ?Rn . } .
          OPTIONAL { ?x chembox:Ru ?Ru . } .
          OPTIONAL { ?x chembox:S ?S . } .
          OPTIONAL { ?x chembox:Sb ?Sb . } .
          OPTIONAL { ?x chembox:Sc ?Sc . } .
          OPTIONAL { ?x chembox:Se ?Se . } .
          OPTIONAL { ?x chembox:Sg ?Sg . } .
          OPTIONAL { ?x chembox:Si ?Si . } .
          OPTIONAL { ?x chembox:Sm ?Sm . } .
          OPTIONAL { ?x chembox:Sn ?Sn . } .
          OPTIONAL { ?x chembox:Sr ?Sr . } .
          OPTIONAL { ?x chembox:Ta ?Ta . } .
          OPTIONAL { ?x chembox:Tb ?Tb . } .
          OPTIONAL { ?x chembox:Tc ?Tc . } .
          OPTIONAL { ?x chembox:Te ?Te . } .
          OPTIONAL { ?x chembox:Th ?Th . } .
          OPTIONAL { ?x chembox:Ti ?Ti . } .
          OPTIONAL { ?x chembox:Tl ?Tl . } .
          OPTIONAL { ?x chembox:Tm ?Tm . } .
          OPTIONAL { ?x chembox:U ?U . } .
          OPTIONAL { ?x chembox:Uub ?Uub . } .
          OPTIONAL { ?x chembox:Uuh ?Uuh . } .
          OPTIONAL { ?x chembox:Uuo ?Uuo . } .
          OPTIONAL { ?x chembox:Uup ?Uup . } .
          OPTIONAL { ?x chembox:Uuq ?Uuq . } .
          OPTIONAL { ?x chembox:Uus ?Uus . } .
          OPTIONAL { ?x chembox:Uut ?Uut . } .
          OPTIONAL { ?x chembox:V ?V . } .
          OPTIONAL { ?x chembox:W ?W . } .
          OPTIONAL { ?x chembox:Xe ?Xe . } .
          OPTIONAL { ?x chembox:Y ?Y . } .
          OPTIONAL { ?x chembox:Yb ?Yb . } .
          OPTIONAL { ?x chembox:Zn ?Zn . } .
          OPTIONAL { ?x chembox:Zr ?Zr . } .
          BIND (IF(bound(?C), fn:concat("C", ?C), "") AS ?C1) .
          BIND (IF(bound(?H), fn:concat("H", ?H), "") AS ?H1) .
          BIND (IF(bound(?Ac), fn:concat("Ac", ?Ac), "") AS ?Ac1) .
          BIND (IF(bound(?Ag), fn:concat("Ag", ?Ag), "") AS ?Ag1) .
          BIND (IF(bound(?Al), fn:concat("Al", ?Al), "") AS ?Al1) .
          BIND (IF(bound(?Am), fn:concat("Am", ?Am), "") AS ?Am1) .
          BIND (IF(bound(?Ar), fn:concat("Ar", ?Ar), "") AS ?Ar1) .
          BIND (IF(bound(?As), fn:concat("As", ?As), "") AS ?As1) .
          BIND (IF(bound(?At), fn:concat("At", ?At), "") AS ?At1) .
          BIND (IF(bound(?Au), fn:concat("Au", ?Au), "") AS ?Au1) .
          BIND (IF(bound(?B), fn:concat("B", ?B), "") AS ?B1) .
          BIND (IF(bound(?Ba), fn:concat("Ba", ?Ba), "") AS ?Ba1) .
          BIND (IF(bound(?Be), fn:concat("Be", ?Be), "") AS ?Be1) .
          BIND (IF(bound(?Bh), fn:concat("Bh", ?Bh), "") AS ?Bh1) .
          BIND (IF(bound(?Bi), fn:concat("Bi", ?Bi), "") AS ?Bi1) .
          BIND (IF(bound(?Bk), fn:concat("Bk", ?Bk), "") AS ?Bk1) .
          BIND (IF(bound(?Br), fn:concat("Br", ?Br), "") AS ?Br1) .
          BIND (IF(bound(?Ca), fn:concat("Ca", ?Ca), "") AS ?Ca1) .
          BIND (IF(bound(?Cd), fn:concat("Cd", ?Cd), "") AS ?Cd1) .
          BIND (IF(bound(?Ce), fn:concat("Ce", ?Ce), "") AS ?Ce1) .
          BIND (IF(bound(?Cf), fn:concat("Cf", ?Cf), "") AS ?Cf1) .
          BIND (IF(bound(?Cl), fn:concat("Cl", ?Cl), "") AS ?Cl1) .
          BIND (IF(bound(?Cm), fn:concat("Cm", ?Cm), "") AS ?Cm1) .
          BIND (IF(bound(?Co), fn:concat("Co", ?Co), "") AS ?Co1) .
          BIND (IF(bound(?Cr), fn:concat("Cr", ?Cr), "") AS ?Cr1) .
          BIND (IF(bound(?Cs), fn:concat("Cs", ?Cs), "") AS ?Cs1) .
          BIND (IF(bound(?Cu), fn:concat("Cu", ?Cu), "") AS ?Cu1) .
          BIND (IF(bound(?Db), fn:concat("Db", ?Db), "") AS ?Db1) .
          BIND (IF(bound(?Ds), fn:concat("Ds", ?Ds), "") AS ?Ds1) .
          BIND (IF(bound(?Dy), fn:concat("Dy", ?Dy), "") AS ?Dy1) .
          BIND (IF(bound(?Er), fn:concat("Er", ?Er), "") AS ?Er1) .
          BIND (IF(bound(?Es), fn:concat("Es", ?Es), "") AS ?Es1) .
          BIND (IF(bound(?Eu), fn:concat("Eu", ?Eu), "") AS ?Eu1) .
          BIND (IF(bound(?F), fn:concat("F", ?F), "") AS ?F1) .
          BIND (IF(bound(?Fe), fn:concat("Fe", ?Fe), "") AS ?Fe1) .
          BIND (IF(bound(?Fm), fn:concat("Fm", ?Fm), "") AS ?Fm1) .
          BIND (IF(bound(?Fr), fn:concat("Fr", ?Fr), "") AS ?Fr1) .
          BIND (IF(bound(?Ga), fn:concat("Ga", ?Ga), "") AS ?Ga1) .
          BIND (IF(bound(?Gd), fn:concat("Gd", ?Gd), "") AS ?Gd1) .
          BIND (IF(bound(?Ge), fn:concat("Ge", ?Ge), "") AS ?Ge1) .
          BIND (IF(bound(?He), fn:concat("He", ?He), "") AS ?He1) .
          BIND (IF(bound(?Hf), fn:concat("Hf", ?Hf), "") AS ?Hf1) .
          BIND (IF(bound(?Hg), fn:concat("Hg", ?Hg), "") AS ?Hg1) .
          BIND (IF(bound(?Ho), fn:concat("Ho", ?Ho), "") AS ?Ho1) .
          BIND (IF(bound(?Hs), fn:concat("Hs", ?Hs), "") AS ?Hs1) .
          BIND (IF(bound(?I), fn:concat("I", ?I), "") AS ?I1) .
          BIND (IF(bound(?In), fn:concat("In", ?In), "") AS ?In1) .
          BIND (IF(bound(?Ir), fn:concat("Ir", ?Ir), "") AS ?Ir1) .
          BIND (IF(bound(?K), fn:concat("K", ?K), "") AS ?K1) .
          BIND (IF(bound(?Kr), fn:concat("Kr", ?Kr), "") AS ?Kr1) .
          BIND (IF(bound(?La), fn:concat("La", ?La), "") AS ?La1) .
          BIND (IF(bound(?Li), fn:concat("Li", ?Li), "") AS ?Li1) .
          BIND (IF(bound(?Lr), fn:concat("Lr", ?Lr), "") AS ?Lr1) .
          BIND (IF(bound(?Lu), fn:concat("Lu", ?Lu), "") AS ?Lu1) .
          BIND (IF(bound(?Md), fn:concat("Md", ?Md), "") AS ?Md1) .
          BIND (IF(bound(?Mg), fn:concat("Mg", ?Mg), "") AS ?Mg1) .
          BIND (IF(bound(?Mn), fn:concat("Mn", ?Mn), "") AS ?Mn1) .
          BIND (IF(bound(?Mo), fn:concat("Mo", ?Mo), "") AS ?Mo1) .
          BIND (IF(bound(?Mt), fn:concat("Mt", ?Mt), "") AS ?Mt1) .
          BIND (IF(bound(?N), fn:concat("N", ?N), "") AS ?N1) .
          BIND (IF(bound(?Na), fn:concat("Na", ?Na), "") AS ?Na1) .
          BIND (IF(bound(?Nb), fn:concat("Nb", ?Nb), "") AS ?Nb1) .
          BIND (IF(bound(?Nd), fn:concat("Nd", ?Nd), "") AS ?Nd1) .
          BIND (IF(bound(?Ne), fn:concat("Ne", ?Ne), "") AS ?Ne1) .
          BIND (IF(bound(?Ni), fn:concat("Ni", ?Ni), "") AS ?Ni1) .
          BIND (IF(bound(?No), fn:concat("No", ?No), "") AS ?No1) .
          BIND (IF(bound(?Np), fn:concat("Np", ?Np), "") AS ?Np1) .
          BIND (IF(bound(?O), fn:concat("O", ?O), "") AS ?O1) .
          BIND (IF(bound(?Os), fn:concat("Os", ?Os), "") AS ?Os1) .
          BIND (IF(bound(?P), fn:concat("P", ?P), "") AS ?P1) .
          BIND (IF(bound(?Pa), fn:concat("Pa", ?Pa), "") AS ?Pa1) .
          BIND (IF(bound(?Pb), fn:concat("Pb", ?Pb), "") AS ?Pb1) .
          BIND (IF(bound(?Pd), fn:concat("Pd", ?Pd), "") AS ?Pd1) .
          BIND (IF(bound(?Pm), fn:concat("Pm", ?Pm), "") AS ?Pm1) .
          BIND (IF(bound(?Po), fn:concat("Po", ?Po), "") AS ?Po1) .
          BIND (IF(bound(?Pr), fn:concat("Pr", ?Pr), "") AS ?Pr1) .
          BIND (IF(bound(?Pt), fn:concat("Pt", ?Pt), "") AS ?Pt1) .
          BIND (IF(bound(?Pu), fn:concat("Pu", ?Pu), "") AS ?Pu1) .
          BIND (IF(bound(?Ra), fn:concat("Ra", ?Ra), "") AS ?Ra1) .
          BIND (IF(bound(?Rb), fn:concat("Rb", ?Rb), "") AS ?Rb1) .
          BIND (IF(bound(?Re), fn:concat("Re", ?Re), "") AS ?Re1) .
          BIND (IF(bound(?Rf), fn:concat("Rf", ?Rf), "") AS ?Rf1) .
          BIND (IF(bound(?Rg), fn:concat("Rg", ?Rg), "") AS ?Rg1) .
          BIND (IF(bound(?Rh), fn:concat("Rh", ?Rh), "") AS ?Rh1) .
          BIND (IF(bound(?Rn), fn:concat("Rn", ?Rn), "") AS ?Rn1) .
          BIND (IF(bound(?Ru), fn:concat("Ru", ?Ru), "") AS ?Ru1) .
          BIND (IF(bound(?S), fn:concat("S", ?S), "") AS ?S1) .
          BIND (IF(bound(?Sb), fn:concat("Sb", ?Sb), "") AS ?Sb1) .
          BIND (IF(bound(?Sc), fn:concat("Sc", ?Sc), "") AS ?Sc1) .
          BIND (IF(bound(?Se), fn:concat("Se", ?Se), "") AS ?Se1) .
          BIND (IF(bound(?Sg), fn:concat("Sg", ?Sg), "") AS ?Sg1) .
          BIND (IF(bound(?Si), fn:concat("Si", ?Si), "") AS ?Si1) .
          BIND (IF(bound(?Sm), fn:concat("Sm", ?Sm), "") AS ?Sm1) .
          BIND (IF(bound(?Sn), fn:concat("Sn", ?Sn), "") AS ?Sn1) .
          BIND (IF(bound(?Sr), fn:concat("Sr", ?Sr), "") AS ?Sr1) .
          BIND (IF(bound(?Ta), fn:concat("Ta", ?Ta), "") AS ?Ta1) .
          BIND (IF(bound(?Tb), fn:concat("Tb", ?Tb), "") AS ?Tb1) .
          BIND (IF(bound(?Tc), fn:concat("Tc", ?Tc), "") AS ?Tc1) .
          BIND (IF(bound(?Te), fn:concat("Te", ?Te), "") AS ?Te1) .
          BIND (IF(bound(?Th), fn:concat("Th", ?Th), "") AS ?Th1) .
          BIND (IF(bound(?Ti), fn:concat("Ti", ?Ti), "") AS ?Ti1) .
          BIND (IF(bound(?Tl), fn:concat("Tl", ?Tl), "") AS ?Tl1) .
          BIND (IF(bound(?Tm), fn:concat("Tm", ?Tm), "") AS ?Tm1) .
          BIND (IF(bound(?U), fn:concat("U", ?U), "") AS ?U1) .
          BIND (IF(bound(?Uub), fn:concat("Uub", ?Uub), "") AS ?Uub1) .
          BIND (IF(bound(?Uuh), fn:concat("Uuh", ?Uuh), "") AS ?Uuh1) .
          BIND (IF(bound(?Uuo), fn:concat("Uuo", ?Uuo), "") AS ?Uuo1) .
          BIND (IF(bound(?Uup), fn:concat("Uup", ?Uup), "") AS ?Uup1) .
          BIND (IF(bound(?Uuq), fn:concat("Uuq", ?Uuq), "") AS ?Uuq1) .
          BIND (IF(bound(?Uus), fn:concat("Uus", ?Uus), "") AS ?Uus1) .
          BIND (IF(bound(?Uut), fn:concat("Uut", ?Uut), "") AS ?Uut1) .
          BIND (IF(bound(?V), fn:concat("V", ?V), "") AS ?V1) .
          BIND (IF(bound(?W), fn:concat("W", ?W), "") AS ?W1) .
          BIND (IF(bound(?Xe), fn:concat("Xe", ?Xe), "") AS ?Xe1) .
          BIND (IF(bound(?Y), fn:concat("Y", ?Y), "") AS ?Y1) .
          BIND (IF(bound(?Yb), fn:concat("Yb", ?Yb), "") AS ?Yb1) .
          BIND (IF(bound(?Zn), fn:concat("Zn", ?Zn), "") AS ?Zn1) .
          BIND (IF(bound(?Zr), fn:concat("Zr", ?Zr), "") AS ?Zr1) . }


### Solubility

    :Solubility
          rdf:type mim:DataRequirement .

A solubility description is an optional (MAY) requirement, which is indicated simply by a chembox:Solubility statement.

    CONSTRUCT 
        { ?x mim:containsDataReport _:b0 .
          _:b0 mim:reports chembox-mim:Solubility .
          _:b0 mim:withValue ?value . }
    WHERE
        { ?x chembox:Solubility ?value . }



### MeltingPoint

    :MeltingPoint
        rdf:type mim:RequirementSet ;
        mim:hasMustRequirement :MeltingPointUnits , :MeltingPointValue ;
        mim:hasRestriction
          [ mim:exactCardinality 1 ;
            mim:onRequirement :MeltingPointUnits , :MeltingPointValue ] .

    :MeltingPointUnits
        rdf:type mim:DataRequirement . 

    :MeltingPointValue
        rdf:type mim:DataRequirement .

This involves a relatively complex query that generates three separate reports as required: a :MeltingPoint report, and :MeltingPointUnits and :MeltingPointValue reports, of which there must be exactly one of each.  (Here, we see a mim:RequirementSet value is generated directly by the SPIN rule, which is a little surprising.)

    CONSTRUCT
      { ?x mim:containsReportSet _:b0 .
        _:b0 mim:containsDataReport _:b1 .
        _:b0 mim:containsDataReport _:b2 .
        _:b0 mim:reports chembox-mim:MeltingPoint .
        _:b1 mim:reports chembox-mim:MeltingPointValue .
        _:b1 mim:withValue ?value .
        _:b2 mim:reports chembox-mim:MeltingPointUnits .
        _:b2 mim:withValue ?units . }
    WHERE
      { OPTIONAL
          { ?x (chembox:MeltingPtK|chembox:MeltingPtKL)|chembox:MeltingPtKH ?value .
            BIND ("K" AS ?units) . } .
        OPTIONAL
          { ?x (chembox:MeltingPtC|chembox:MeltingPtCL)|chembox:MeltingPtCH ?value .
            BIND ("C" AS ?units) . } .
      }

There are also some related rules that appear to require melting points separately in C or K units:

    CONSTRUCT 
      { ?x mim:containsReportSet _:b0 .
        _:b0 mim:containsDataReport _:b1 .
        _:b0 mim:containsDataReport _:b2 .
        _:b0 mim:reports chembox-mim:MeltingPoint .
        _:b1 mim:reports chembox-mim:MeltingPointValue .
        _:b1 mim:withValue ?value .
        _:b2 mim:reports chembox-mim:MeltingPointUnits .
        _:b2 mim:withValue ?units . }
    WHERE
      { ?x chembox:MeltingPt ?value .
        BIND (regex(?value, "K$", "i") AS ?k) .
        BIND (IF(?k, "K", "") AS ?units) .
        FILTER (?units != "") . }

and

    CONSTRUCT
      { ?x mim:containsReportSet _:b0 .
        _:b0 mim:containsDataReport _:b1 .
        _:b0 mim:containsDataReport _:b2 .
        _:b0 mim:reports chembox-mim:MeltingPoint .
        _:b1 mim:reports chembox-mim:MeltingPointValue .
        _:b1 mim:withValue ?value .
        _:b2 mim:reports chembox-mim:MeltingPointUnits .
        _:b2 mim:withValue ?units . }
    WHERE
      { ?x chembox:MeltingPt ?value .
        BIND (regex(?value, "C$", "i") AS ?c) .
        BIND (IF(?c, "C", "") AS ?units) .
        FILTER (?units != "") . }


### MolarMass

    :MolarMass
          rdf:type mim:DataRequirement .

The molar mass description is a SHOULD requirement that simply looks for the presence of a chembox:MolarMass value:

    CONSTRUCT
      { ?x mim:containsDataReport _:b0 .
        _:b0 mim:reports chembox-mim:MolarMass .
        _:b0 mim:withValue ?value . }
    WHERE
      { ?x chembox:MolarMass ?value . }


## Other requirements

### Synonym

    :Synonym
          rdf:type mim:DataRequirement .

A synonym is an optional; (MAY) requirement that simply looks for the presence of a chembox:OtherNames value:

    CONSTRUCT
      { ?x mim:containsDataReport _:b0 .
        _:b0 mim:reports chembox-mim:Synonym .
        _:b0 mim:withValue ?value . }
    WHERE
      { ?x chembox:OtherNames ?value . }


### IUPACName

    :IUPACName
    	rdf:type mim:DataRequirement . 

A simple test for available information:

    CONSTRUCT
      { ?x mim:containsDataReport _:b0 .
        _:b0 mim:reports chembox-mim:IUPACName .
        _:b0 mim:withValue ?value . }
    WHERE
      { ?x chembox:IUPACName ?value . }


### Image

    :Image 
    	rdf:type mim:DataRequirement . 

Looks for statements using one of three properties, and manipulates the result to construct a URI for the image resource.  In this respect (constructing the URI) it goes beyond the requirements of simple metadata checking, but the resulting URI might be useful for liveness testing.

    CONSTRUCT {
        ?x mim:containsDataReport _:b0 .
        _:b0 mim:reports chembox-mim:Image .
        _:b0 mim:withValue ?value .
        ?value a <http://xmlns.com/foaf/0.1/Image> .
    }
    WHERE {
        ?x (chembox:ImageFile|chembox:ImageFileL1)|chembox:ImageFileR1 ?f .
        BIND (IRI(fn:concat("http://en.wikipedia.org/File:", ?f)) AS ?value) .
    }
