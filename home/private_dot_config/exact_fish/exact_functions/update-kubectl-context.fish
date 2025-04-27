function update-kubectl-context
    for c in (aws eks list-clusters | jq -r '.clusters | .[]')
        aws eks update-kubeconfig --name $c
    end
end
