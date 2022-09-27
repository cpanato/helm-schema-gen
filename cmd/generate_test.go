package cmd

import (
	"path/filepath"
	"testing"
)

func BenchmarkRootCommandExecution(b *testing.B) {
	for i := 0; i < b.N; i++ {
		testr := NewGenerateCmd()
		err := testr.RunE(nil, []string{filepath.Join("..", "testdata", "values.yaml")})
		if err != nil {
			b.Fatal(err)
		}
	}
}
