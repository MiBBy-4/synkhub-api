# frozen_string_literal: true

module Api
  module V1
    module JsonResponders
      extend ActiveSupport::Concern

      included do
        rescue_from ActionController::ParameterMissing, with: :respond_with_bad_request
        rescue_from ActiveRecord::RecordNotFound, with: :respond_with_not_found
      end

      def respond_with_query_results(pagy, results, serializer:, serializer_options: {}, meta: {})
        meta[:pagination] = pagination_meta(pagy) if pagy

        respond_with_serialized_resources_collection(
          results, serializer: serializer, serializer_options: serializer_options, meta: meta
        )
      end

      def respond_with_service_result(result, serializer:, serializer_options: {}, meta: {})
        if result.success?
          respond_with_serialized_resource(
            result.value,
            serializer: serializer,
            serializer_options: serializer_options,
            meta: meta
          )
        else
          respond_with_unprocessable_entity(result.error)
        end
      end

      def respond_with_no_content_service_result(result)
        if result.success?
          head :no_content
        else
          respond_with_unprocessable_entity(result.error)
        end
      end

      def respond_with_service_result_collection(result, serializer:, serializer_options: {}, meta: {})
        if result.success?
          respond_with_serialized_resources_collection(
            result.value,
            serializer: serializer,
            serializer_options: serializer_options,
            meta: meta
          )
        else
          respond_with_unprocessable_entity(result.error)
        end
      end

      def respond_with_serialized_resources_collection(resources, serializer:, serializer_options: {}, meta: {})
        serialized_data = serializer.new(resources, params: serializer_options).serializable_hash

        render json: { data: serialized_data, meta: meta }
      end

      def respond_with_serialized_resource(resource, serializer:, serializer_options: {}, meta: {})
        render json: { data: serializer.new(resource, params: serializer_options).serializable_hash, meta: meta }
      end

      def respond_with_authenticated_service_result(result, serializer:, status: :ok, error_status: :unprocessable_entity, serializer_options: {}, meta: {})
        if result.success?
          token = Api::V1::Jwt::Encoder.call(user: result.value).value
          data = serializer.new(result.value, params: serializer_options).serializable_hash.merge(token: token)

          render json: { data: data, meta: meta }, status: status
        else
          respond_with_errors(errors: result.error, status: error_status)
        end
      end

      def respond_with_unprocessable_entity(errors)
        respond_with_errors(errors: errors, status: :unprocessable_entity)
      end

      def respond_with_unauthorized(message = "You are unauthorized")
        respond_with_errors(errors: message, status: :unauthorized)
      end

      def respond_with_bad_request
        respond_with_errors(errors: "Bad Request", status: :bad_request)
      end

      def respond_with_not_found
        respond_with_errors(errors: "Not Found", status: :not_found)
      end

      def respond_with_errors(errors:, status:)
        errors = [errors] unless errors.is_a?(Array)

        render json: { errors: errors }, status: status
      end

      private

      def pagination_meta(pagy)
        if pagy.is_a?(Pagy::Countless) && pagy.vars[:countless_minimal]
          {
            current_page: pagy.page,
            per_page: pagy.limit,
          }
        elsif pagy.is_a?(Pagy::Countless)
          {
            current_page: pagy.page,
            per_page: pagy.limit,
            next_page: pagy.next,
            previous_page: pagy.prev,
          }
        else
          {
            current_page: pagy.page,
            per_page: pagy.limit,
            next_page: pagy.next,
            previous_page: pagy.prev,
            total_pages: pagy.last,
            total_count: pagy.count,
          }
        end
      end
    end
  end
end
