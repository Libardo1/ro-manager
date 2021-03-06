#!/bin/bash
HOST=http://andros.zoo.ox.ac.uk:8080    # Service endpoint URI

# Retrieve service description and extract template

echo "==== Retrieve URI template for evaluate checklist ===="
TEMPLATE=`asq -r "http://andros.zoo.ox.ac.uk:8080/" -f "%(t)s" "SELECT ?t WHERE { ?s <http://purl.org/ro/service/evaluate/checklist> ?t }"`
echo "==== Template: <$TEMPLATE>"

# URI template expansion
echo "==== Request URI-template expansion ===="
cat >sample-params.txt <<END
{
  "template": "$TEMPLATE",
  "params":
  {
    "RO": "http://andros.zoo.ox.ac.uk/workspace/wf4ever-ro-catalogue/v0.1/wf74-repeat-fail",
    "minim": "simple-requirements-minim.rdf",
    "purpose": "Repeatable"
  }
}
END

EVALURI=$HOST`curl -X POST --data @sample-params.txt $HOST/uritemplate`

echo "==== URI: $EVALURI"

# Evaluation results with URI parameters:

echo "==== Request evaluation result with parameters, as RDF/Turtle ===="
curl -H "accept: text/turtle" $EVALURI

#echo "==== Request evaluation result with parameters, as RDF/XML ===="
#curl -H "accept: application/rdf+xml" $EVALURI

# End.
