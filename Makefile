build:
	ruby scripts/build_menu.rb

deploy: build
	cd infra && npx cdk deploy --require-approval never --outputs-file ../dist/cdk-outputs.json
	aws s3 cp dist/index.html s3://ddmskcoffeeshop/index.html --content-type "text/html"
	aws cloudfront create-invalidation --distribution-id "$$(jq -r '.[].DistributionId' dist/cdk-outputs.json)" --paths "/index.html"

serve: build
	python3 -m http.server 8000 --directory dist
