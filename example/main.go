package main

import (
	"context"
	"fmt"
	"log"
	"net/http"

	"github.com/99designs/gqlgen/graphql/handler"
	"github.com/99designs/gqlgen/graphql/playground"
	"github.com/Silicon-Ally/rules_gqlgen/example/generated"
	"github.com/Silicon-Ally/rules_gqlgen/example/model"
)

func main() {
	srv := handler.NewDefaultServer(generated.NewExecutableSchema(generated.Config{Resolvers: &Resolver{}}))

	mux := http.NewServeMux()
	mux.Handle("/api/graphql", srv)
	mux.Handle("/api/playground", playground.Handler("GraphQL playground", "/api/graphql"))

	if err := http.ListenAndServe(":8080", mux); err != nil {
		log.Fatalf("http.ListenAndServe: %v", err)
	}
}

type Resolver struct{ name string }

func (r *queryResolver) Greetings(ctx context.Context) ([]*model.Greeting, error) {
	if r.name == "" {
		return []*model.Greeting{
			{
				Message: "Hello there!",
				Lang:    "en",
			},
			{
				Message: "¡Hola!",
				Lang:    "es",
			},
		}, nil
	}
	return []*model.Greeting{
		{
			Message: fmt.Sprintf("Hey there %s!", r.name),
			Lang:    "en",
		},
		{
			Message: fmt.Sprintf("¡Hola %s!", r.name),
			Lang:    "es",
		},
	}, nil
}

func (r *mutationResolver) UpdateName(ctx context.Context, req model.UpdateGreetingRequest) (*bool, error) {
	r.name = req.Name
	return success()
}

func success() (*bool, error) {
	v := true
	return &v, nil
}

type (
	mutationResolver struct{ *Resolver }
	queryResolver    struct{ *Resolver }
)

// Mutation returns generated.MutationResolver implementation.
func (r *Resolver) Mutation() generated.MutationResolver { return &mutationResolver{r} }

// Query returns generated.QueryResolver implementation.
func (r *Resolver) Query() generated.QueryResolver { return &queryResolver{r} }
