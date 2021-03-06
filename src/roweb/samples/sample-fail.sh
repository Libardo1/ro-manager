#!/bin/bash
HOST=http://andros.zoo.ox.ac.uk:8080    # Service endpoint URI

# Retrieve service description and extract template

echo "==== Retrieve URI template for evaluate checklist ===="
TEMPLATE=`curl -H "accept: text/turtle" $HOST/ | sed -n 's/^.*roe:checklist[ ]*"\([^"]*\)".*$/\1/p'`
echo "==== Template: <$TEMPLATE>"

# URI template expansion

echo "==== Request URI-template expansion ===="
cat >sample-params.txt <<END
{
  "template": "$TEMPLATE",
  "params":
  {
    "RO": "http://andros.zoo.ox.ac.uk/aleix/ro-catalogue/v0.1/wf74-repeat-fail",
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
