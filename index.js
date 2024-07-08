exports.handler = async (event) => {
    return {
        statusCode: 200,
        headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': '*',
            'Access-Control-Allow-Methods': '*',
        },
        body: JSON.stringify('Hello World!'),
    };
};
