import Foundation

struct MockData {
    static let papers: [Paper] = [
        Paper(
            id: "1706.03762",
            title: "Attention Is All You Need",
            authors: ["Ashish Vaswani", "Noam Shazeer", "Niki Parmar", "et al."],
            summary: "The dominant sequence transduction models are based on complex recurrent or convolutional neural networks that include an encoder and a decoder. The best performing models also connect the encoder and decoder through an attention mechanism. We propose a new simple network architecture, the Transformer, based solely on attention mechanisms, dispensing with recurrence and convolutions entirely.",
            published: Date(),
            linkURL: URL(string: "https://arxiv.org/abs/1706.03762"),
            primaryCategory: "cs.CL"
        ),
        Paper(
            id: "1810.04805",
            title: "BERT: Pre-training of Deep Bidirectional Transformers for Language Understanding",
            authors: ["Jacob Devlin", "Ming-Wei Chang", "Kenton Lee", "Kristina Toutanova"],
            summary: "We introduce a new language model called BERT. BERT is designed to pre-train deep bidirectional representations from unlabeled text by jointly conditioning on both left and right context in all layers.",
            published: Date(),
            linkURL: URL(string: "https://arxiv.org/abs/1810.04805"),
            primaryCategory: "cs.CL"
        ),
        Paper(
            id: "1512.03385",
            title: "Deep Residual Learning for Image Recognition",
            authors: ["Kaiming He", "Xiangyu Zhang", "Shaoqing Ren", "Jian Sun"],
            summary: "Deeper neural networks are more difficult to train. We present a residual learning framework to ease the training of networks that are substantially deeper than those used previously.",
            published: Date(),
            linkURL: URL(string: "https://arxiv.org/abs/1512.03385"),
            primaryCategory: "cs.CV"
        ),
        Paper(
            id: "1406.2661",
            title: "Generative Adversarial Nets",
            authors: ["Ian J. Goodfellow", "Jean Pouget-Abadie", "Mehdi Mirza", "et al."],
            summary: "We propose a new framework for estimating generative models via an adversarial process, in which we simultaneously train two models: a generative model G that captures the data distribution, and a discriminative model D that estimates the probability that a sample came from the training data rather than G.",
            published: Date(),
            linkURL: URL(string: "https://arxiv.org/abs/1406.2661"),
            primaryCategory: "cs.LG"
        ),
        Paper(
            id: "1200.0001",
            title: "ImageNet Classification with Deep Convolutional Neural Networks",
            authors: ["Alex Krizhevsky", "Sutskever", "Hinton"],
            summary: "We trained a large, deep convolutional neural network to classify the 1.2 million high-resolution images in the ImageNet LSVRC-2010 contest into the 1000 different classes.",
            published: Date(),
            linkURL: URL(string: "http://www.cs.toronto.edu/~kriz/imagenet_classification.pdf"),
            primaryCategory: "cs.CV"
        ),
        Paper(
            id: "1312.5602",
            title: "Playing Atari with Deep Reinforcement Learning",
            authors: ["Volodymyr Mnih", "Kavukcuoglu", "Silver", "et al."],
            summary: "We present the first deep learning model to successfully learn control policies directly from high-dimensional sensory input using reinforcement learning.",
            published: Date(),
            linkURL: URL(string: "https://arxiv.org/abs/1312.5602"),
            primaryCategory: "cs.LG"
        )
    ]
}
