package main

import (
	"context"
	"flag"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	// "github.com/c4milo/unpackit"
	"net/url"
	"os"
	"io"
	//"os/exec"
)

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}

func main() {
	s3Uri := flag.String(
		"uri",
		getEnv("CONDA_LAMBDA_URI", "s3://nf-testing-juliet/layers/layer.tar.bz2"),
		"S3 URI to tar.bz2 conda-packed archive.")
	flag.Parse()

	cfg, err := config.LoadDefaultConfig(context.TODO())

	if err != nil {
		panic("Failed to load configuration")
	}

	s3client := s3.NewFromConfig(cfg)

	u, _ := url.Parse(*s3Uri)
	getObjectInput := s3.GetObjectInput{
		Bucket: aws.String(u.Host),
		Key:    aws.String(u.Path[1:]),
	}
	if u.Query().Has("VersionId") && u.Query().Get("VersionId") != "" {
		getObjectInput.VersionId = aws.String(u.Query().Get("VersionId"))
	}
	getObjectResponse, err := s3client.GetObject(context.TODO(), &getObjectInput)
	if err != nil {
		panic("Couldn't download object: " + err.Error())
	}
	
	/*
	file, err := os.Create("/tmp/layer.tar.bz2")

	if err != nil {
		panic("didnt open file to write: " + err.Error())
	}
	*/
	written, err := io.Copy(os.Stdout, getObjectResponse.Body)
	if err != nil {
		panic("Failed to write file contents! " + err.Error())
	} else if written != getObjectResponse.ContentLength {
		panic("wrote a different size than was given to us")
	}
	//file.Close()

	/*
	err = os.RemoveAll("/tmp/lambda")
	if err != nil {
		panic("Error remove /tmp/lambda: " + err.Error())
	}

	err = unpackit.Unpack(getObjectResponse.Body, "/tmp")
	if err != nil {
		panic("Error unpacking file: " + err.Error())
	}

	/*
	cmd := exec.CommandContext(context.TODO(), "/tmp/lambda/bootstrap")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin
	cmd.Env = os.Environ()
	err = cmd.Run()
	if err != nil {
		panic("Error running bootstrap: " + err.Error())
	}
	*/
}
