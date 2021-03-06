

KUBE_RESOURCES := $(shell pwd)/install
MINIKUBE := $(shell command -v minikube)



#----------------------------------------------------------------------------------
# Deploy services
#----------------------------------------------------------------------------------

.PHONY: deploy-apigateway-with-catalog
deploy-apigateway-with-catalog:
	-istioctl kube-inject -f $(KUBE_RESOURCES)/catalog-service/catalog-all.yaml | kubectl create -f -
	-istioctl kube-inject -f $(KUBE_RESOURCES)/apigateway-service/apigateway-all.yaml | kubectl create -f -
	-kubectl apply -f $(KUBE_RESOURCES)/istio/


.PHONY: undeploy-apigateway-with-catalog
undeploy-apigateway-with-catalog:
	-kubectl delete svc catalog
	-kubectl delete deploy catalog
	-kubectl delete svc apigateway
	-kubectl delete deploy apigateway
	-kubectl delete -f $(KUBE_RESOURCES)/istio/

.PHONY: ingress-url
ingress-url:
ifdef MINIKUBE
	@echo $(shell kubectl get pod -n istio-system -l istio=ingressgateway -o jsonpath='{.items[0].status.hostIP}'):$(shell kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
endif
# docker-for-desktop uses localhost
ifndef MINIKUBE 
	@echo "localhost"
endif

.PHONY: ingress-pod
ingress-pod:
	@echo $(shell kubectl get pod -l app=istio-ingressgateway -o jsonpath={.items..metadata.name} -n istio-system)

.PHONY: apigateway-pod
apigateway-pod:
	@echo $(shell kubectl get pod -l app=apigateway -o jsonpath={.items..metadata.name} -n istioinaction)

.PHONY: catalog-pod
catalog-pod:
	@echo $(shell kubectl get pod -l app=catalog -o jsonpath={.items..metadata.name} -n istioinaction)

.PHONY: sleep-pod
sleep-pod:
	@echo $(shell kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name} -n default)

.PHONY: statsd-pod
statsd-pod:
	@echo $(shell kubectl get pod -l run=statsd -o jsonpath={.items..metadata.name} -n istioinaction)

.PHONY: ingress-pod
ingress-pod:
	@echo $(shell kubectl get pod -l app=istio-ingressgateway -o jsonpath={.items..metadata.name} -n istio-system)

.PHONY: apigateway-pod
apigateway-pod:
	@echo $(shell kubectl get pod -l app=apigateway -o jsonpath={.items..metadata.name} -n istioinaction)

.PHONY: catalog-pod
catalog-pod:
	@echo $(shell kubectl get pod -l app=catalog -o jsonpath={.items..metadata.name} -n istioinaction)

.PHONY: sleep-pod
sleep-pod:
	@echo $(shell kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name} -n default)

.PHONY: ingress-pod
ingress-pod:
	@echo $(shell kubectl get pod -l app=istio-ingressgateway -o jsonpath={.items..metadata.name} -n istio-system)

.PHONY: apigateway-pod
apigateway-pod:
	@echo $(shell kubectl get pod -l app=apigateway -o jsonpath={.items..metadata.name} -n istioinaction)

.PHONY: catalog-pod
catalog-pod:
	@echo $(shell kubectl get pod -l app=catalog -o jsonpath={.items..metadata.name} -n istioinaction)

.PHONY: sleep-pod
sleep-pod:
	@echo $(shell kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name} -n default)

.PHONY: get-demo-curl
get-demo-curl:
	@echo 'curl -H "Host: apigateway.istioinaction.io" http://$(shell make ingress-url)/api/products'

.PHONY: chapter8-setup-authn
chapter8-setup-authn:
	-kubectl delete ns istioinaction
	-kubectl create ns istioinaction
	-kubectl -n default delete -f chapters/chapter8/sleep.yaml
	-istioctl kube-inject -f services/catalog/kubernetes/catalog.yaml | kubectl -n istioinaction apply -f -
	-istioctl kube-inject -f services/apigateway/kubernetes/apigateway.yaml | kubectl -n istioinaction apply -f -
	-kubectl -n default apply -f chapters/chapter8/sleep.yaml
	-kubectl apply -f chapters/chapter8/meshwide-strict-peer-authn.yaml
	-kubectl apply -f chapters/chapter8/workload-permissive-peer-authn.yaml

.PHONY: chapter8-setup-authn-authz
chapter8-setup-authn-authz: chapter8-setup-authn
	-kubectl apply -f chapters/chapter8/policy-deny-all-mesh.yaml
	-kubectl apply -f chapters/chapter8/allow-unauthenticated-view-default-ns.yaml
	-kubectl apply -f chapters/chapter8/catalog-viewer-policy.yaml

.PHONY: chapter8-cleanup
chapter8-cleanup:
	-kubectl delete authorizationpolicy --all -n istio-system 2> /dev/null || true
	-kubectl delete authorizationpolicy --all -n istioinaction 2> /dev/null || true
	-kubectl delete requestauthentication --all -n istio-system 2> /dev/null || true
	-kubectl delete requestauthentication --all -n istioinaction 2> /dev/null || true
	-kubectl delete peerauthentication --all -n istioinaction 2> /dev/null || true
	-kubectl delete peerauthentication default -n istio-system 2> /dev/null || true
	-kubectl delete -f chapters/chapter8/sleep.yaml -n default 2> /dev/null || true
	-kubectl delete ns istioinaction 2> /dev/null || true

#----------------------------------------------------------------------------------
# Port forward Observability
#----------------------------------------------------------------------------------
.PHONY: pf-grafana
pf-grafana:
	kubectl port-forward -n istio-system $(shell kubectl get pod -n istio-system | grep -i ^grafana | cut -d ' ' -f 1) 3000:3000 > /dev/null 2>&1 &


.PHONY: pf-prom
pf-prom:
	kubectl port-forward -n istio-system $(shell kubectl get pod -n istio-system | grep -i ^prometheus | cut -d ' ' -f 1) 9090:9090 > /dev/null 2>&1 &

.PHONY: pf-kiali
pf-kiali:
	kubectl port-forward -n istio-system $(shell kubectl get pod -n istio-system | grep -i ^kiali | cut -d ' ' -f 1) 8080:20001 > /dev/null 2>&1 &

.PHONY: pf-obs
pf-obs: pf-grafana pf-kiali pf-prom

.PHONY: clean
clean:
		for pid in $(shell ps aux  | awk '/port-forward/ {print $$2}'); do kill -9 $$pid; done

